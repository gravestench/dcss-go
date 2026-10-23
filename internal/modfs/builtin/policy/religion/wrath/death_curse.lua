-- Source: death-curse.cc. Kiku's wrath uses player-targeted death curses;
-- lasting consequences remain with the shared combat and status owners.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local damage = require("policy.magic.damage")
local forms = require("constants.form_ids")
local gods = require("constants.gods")
local health = require("policy.combat.player_health")
local piety = require("policy.religion.piety")
local player_drain = require("policy.combat.player_drain")
local resistance = require("policy.combat.player_resistance")
local resistance_ids = require("constants.resistance_ids")
local roll = require("policy.combat.roll")
local silence = require("policy.world.silence")
local slow = require("policy.character.slow")
local species_flags = require("constants.species_flags")
local species_ids = require("ids.species")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")
local streams = require("constants.rng_streams")
local undead = require("constants.undead_states")
local vampire = require("policy.character.vampire")

local curse = {}

local effects = {
    {
        id = "message",
        trivial = 80,
        severe = 0,
    },

    {
        id = "pain",
        trivial = 20,
        severe = 40,
    },

    {
        id = "slow",
        trivial = 0,
        severe = 40,
    },

    {
        id = "drain",
        trivial = 0,
        severe = 40,
    },

    {
        id = "torment",
        trivial = 0,
        severe = 40,
    },
}

local common_messages = {
    "You feel homesick.",
    "The world around you seems to dim momentarily.",
    "You feel numb.",
    "Strange energies run through your body.",
    "You shiver with cold.",
    "You sense a malignant aura.",
    "You feel very uncomfortable.",
    "Something just walked over your grave. No, really!",
}

-- The passive is active only during current Kiku worship at two stars and
-- without penance, matching god-passive.cc:have_passive.
local function protected(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    return worship and worship.god_id == gods.KIKUBAAQUDGHA and
        (worship.penance[gods.KIKUBAAQUDGHA] or 0) == 0 and
        piety.rank(gods.KIKUBAAQUDGHA, worship.piety) >= 2
end

-- The message's species-dependent additions follow death-curse.cc order.
-- Only lifeless undead lose smell; form and vampire blood state are live.
local function message_choices(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get(categories.SPECIES, identity.species_id)
    local position = ctx:get(player, component.POSITION)
    local form = ctx:get(player, component.PLAYER_FORM)
    local choices = {}

    for _, text in ipairs(common_messages) do
        choices[#choices + 1] = text
    end

    local lifeless = species.undead_type == undead.UNDEAD or
        (species.undead_type == undead.SEMI_UNDEAD and
            not vampire.alive(ctx, player)) or
        (form and form.form_id == forms.LICH)

    if not lifeless then
        choices[#choices + 1] = "You smell decay."
    end

    local kind = identity.species_id
    local skin = "skin"

    if string.find(kind, "DRACONIAN", 1, true) or
        kind == species_ids.SP_NAGA then
        skin = "scales"
    elseif kind == species_ids.SP_TENGU then
        skin = "feathers"
    elseif kind == species_ids.SP_FELID then
        skin = "fur"
    elseif kind == species_ids.SP_MUMMY then
        skin = "bandages"
    end

    if skin == "bandages" then
        choices[#choices + 1] = "Your bandages flutter."
    else
        local verb = string.sub(skin, -1) == "s" and "prickle." or
            "prickles."

        choices[#choices + 1] = "Your " .. skin .. " " .. verb
    end

    if not silence.at(ctx, position.level_id, position.x, position.y) then
        choices[#choices + 1] = "You hear strange and distant voices."
    end

    local bones = true

    for _, flag in ipairs(species.flags or {}) do
        if flag == species_flags.NO_BONES then
            bones = false
        end
    end

    if bones then
        choices[#choices + 1] = "Your bones ache."
    end

    return choices
end

-- An innocuous curse still draws one message, with no status writes.
local function message(ctx, player)
    local choices = message_choices(ctx, player)
    local index = ctx:random(streams.CARDS, #choices) + 1

    ctx:emit(channels.RELIGION, choices[index])
end

-- attack.cc:attack_strength_punctuation grades pain's text by actual HP
-- loss roll; the weak threshold is seven, medium 18, and strong 36.
local function punctuation(amount)
    if amount < 7 then
        return "."
    end

    if amount < 18 then
        return "!"
    end

    if amount < 36 then
        return "!!"
    end

    local extra = math.floor(math.log(amount / 36) / math.log(2))

    return string.rep("!", 3 + extra)
end

-- Torment immunity changes pain to a harmless message before its damage
-- rolls. Otherwise random2avg consumes exclusive then inclusive bounds.
local function pain(ctx, player, severity)
    if resistance.torment(ctx, player) then
        ctx:emit(channels.RELIGION, "You feel weird for a moment.")

        return
    end

    local amount = 5 + roll.average_two(ctx, streams.CARDS,
        2 * severity)

    ctx:emit(channels.RELIGION,
        "Pain shoots through your body" .. punctuation(amount))
    health.damage(ctx, player, amount, false)
end

-- Player::slow_down passes severity straight to slow_player, which owns
-- stasis, haste conversion, and the saved Slow duration.
local function lethargy(ctx, player, severity)
    ctx:emit(channels.RELIGION, "You feel horribly lethargic.")
    slow.apply(ctx, player, severity)
end

-- Drain first chooses stat loss with severity/27 odds. Its alternate path
-- reduces power by negative-energy resistance before the saved HP drain.
local function draining(ctx, player, severity)
    ctx:emit(channels.RELIGION,
        "You are engulfed in negative energy!")

    if ctx:random(streams.CARDS, 27) < severity then
        local index = ctx:random(streams.CARDS, #stats.ORDER) + 1
        local amount = 1 + roll.average_two(ctx, streams.CARDS,
            math.floor(severity / 3))

        stat_loss.drain(ctx, player, stats.ORDER[index], amount)

        return
    end

    local protection = damage.player_resistance(ctx, player,
        resistance_ids.NEGATIVE_ENERGY)
    local power = math.floor(severity * 100 / 27)

    if protection >= 3 then
        ctx:emit(channels.RELIGION, "You resist.")

        return
    end

    if protection > 0 then
        ctx:emit(channels.RELIGION, "You partially resist.")
        power = math.floor(power / (protection * 2))
    end

    if power > 0 then
        player_drain.apply(ctx, player, power, streams.CARDS)
    end
end

-- death-curse.cc calls torment_cell, which reaches this player alone rather
-- than the seven-cell-radius torment area used by the other wrath branch.
local function torment_cell(ctx, player)
    local current = ctx:get(player, component.HEALTH).current
    local amount = resistance.torment_loss(ctx, player, current)

    if amount <= 0 then
        ctx:emit(channels.RELIGION,
            "You feel a surge of unholy energy.")

        return
    end

    ctx:emit(channels.RELIGION, "Your body is wracked with pain!")
    health.damage(ctx, player, amount, false)
end

-- Preserve the source's signed linear interpolation, including negative
-- message weight above severity 15. C++ division truncates toward zero.
local function choose(ctx, severity)
    local weights = {}
    local total = 0

    for index, effect in ipairs(effects) do
        local numerator = (15 - severity) * effect.trivial +
            severity * effect.severe
        local weight = math.modf(numerator / 15)

        weights[index] = weight
        total = total + weight
    end

    local draw = ctx:random(streams.CARDS, total)
    local cumulative = 0

    for index, effect in ipairs(effects) do
        cumulative = cumulative + weights[index]

        if cumulative > draw then
            return effect.id
        end
    end

    error("death curse weighted draw failed")
end

-- The protection coinflip precedes all effect selection. Each invocation
-- chooses one effect afresh; severity is player XL for Kiku wrath.
function curse.apply(ctx, player, severity)
    if type(severity) ~= "number" or severity % 1 ~= 0 or
        severity < 0 or severity > 27 then
        error("death curse severity must be between zero and 27")
    end

    if protected(ctx, player) then
        if ctx:random(streams.CARDS, 2) == 0 then
            ctx:emit(channels.RELIGION,
                "Kikubaaqudgha averts the curse.")

            return "averted"
        end

        ctx:emit(channels.RELIGION,
            "Kikubaaqudgha partially averts the curse.")
        severity = math.floor(severity / 2)
    end

    local effect = choose(ctx, severity)

    if effect == "message" then
        message(ctx, player)
    elseif effect == "pain" then
        pain(ctx, player, severity)
    elseif effect == "slow" then
        lethargy(ctx, player, severity)
    elseif effect == "drain" then
        draining(ctx, player, severity)
    else
        torment_cell(ctx, player)
    end

    return effect
end

return curse
