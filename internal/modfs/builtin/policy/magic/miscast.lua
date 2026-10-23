-- Source: spl-miscast.cc. Deck miscasts roll level dice, divide by nine
-- with random rounding, then apply one school-specific beam or status.
local beam_damage = require("policy.combat.monster_beams.damage")
local defense = require("policy.combat.monster_defense")
local drain = require("policy.combat.monster_drain")
local flavours = require("constants.beam_flavours")
local magic_damage = require("policy.magic.damage")
local malmutation = require("policy.monsters.malmutation")
local poison = require("policy.combat.monster_poison")
local roll = require("policy.combat.roll")
local schools = require("constants.spell_schools")
local senses = require("policy.character.senses")
local slow = require("policy.combat.monster_slow")
local streams = require("constants.rng_streams")

local miscast = {}

local effects = {
    [schools.CONJURATION] = {
        flavour = flavours.BEAM_MMISSILE,
        text = "crackles with magical energy",
    },
    [schools.FIRE] = {
        flavour = flavours.BEAM_FIRE,
        text = "is blasted with fire",
    },
    [schools.ICE] = {
        flavour = flavours.BEAM_COLD,
        text = "is encased in ice",
    },
    [schools.EARTH] = {
        flavour = flavours.BEAM_FRAG,
        text = "is struck by flying rocks",
    },
    [schools.AIR] = {
        flavour = flavours.BEAM_ELECTRICITY,
        text = "is jolted by electricity",
    },
    [schools.POISON] = {
        flavour = flavours.BEAM_POISON,
        text = "looks incredibly sick",
    },
    [schools.NECROMANCY] = {
        flavour = flavours.BEAM_NEG,
        text = "convulses with pain",
    },
    [schools.HEXES] = {
        special = "slow",
        text = "looks off-balance",
    },
    [schools.TRANSMUTATION] = {
        special = "malmutate",
        text = "twists unnaturally",
    },
}

-- roll_dice(level, fail + level) consumes one draw per die, then
-- div_rand_round preserves the source chance of rounding the remainder up.
local function severity(ctx, level, fail, stream)
    local total = 0

    for _ = 1, level do
        total = total + 1 + ctx:random(stream, fail + level)
    end

    return roll.random_divide(ctx, total, 9, stream)
end

-- Source monster visibility chooses seen or unseen text before any damage
-- can remove the target. The school phrase comes from spl-miscast.cc.
local function message(ctx, target, definition, effect)
    if senses.player_sees_actor(ctx, target) then
        ctx:emit("religion", "The " .. definition.name .. " " ..
            effect.text .. ".")
    elseif senses.player_sees_cell(ctx,
        ctx:get(target, "core.position")) then
        ctx:emit("religion", "Wild magic erupts nearby.")
    end
end

-- The source's non-damaging schools still use the severity roll. Hexes
-- apply Slow; Transmutation delegates mutable bodies to the monster owner.
local function special(ctx, target, definition, effect,
    amount, stream)
    if effect.special == "slow" then
        if amount > 0 then
            slow.apply(ctx, target, definition, amount * 10, stream)
        end
    elseif effect.special == "malmutate" then
        malmutation.apply(ctx, target, definition, stream)
    end
end

-- BEAM_NEG drains before its direct hit, while BEAM_POISON has an
-- independent two-in-three dose chance after resistance is calculated.
local function side_effect(ctx, target, definition, source, school,
    amount, stream)
    if school == schools.NECROMANCY and amount > 0 then
        drain.apply(ctx, target, definition, source, stream, true)
    elseif school == schools.POISON and amount > 0 and
        ctx:random(stream, 3) ~= 0 then
        poison.apply(ctx, target, definition, 1, source)
    end
end

-- A deck caller supplies one school, level, fail roll, and source actor.
-- Resistance, armour, lethal credit, and persistent statuses use existing
-- combat owners; this function never invents a card-only monster field.
function miscast.apply(ctx, target, source, school, level, fail, stream)
    local effect = effects[school]

    if not effect or type(level) ~= "number" or level % 1 ~= 0 or
        level < 1 or type(fail) ~= "number" or fail % 1 ~= 0 or
        fail < 0 then
        error("invalid miscast school or severity")
    end

    local definition, health = magic_damage.monster(ctx, target)

    if not definition or health.current <= 0 then
        return false
    end

    stream = stream or streams.SPELL

    local amount = severity(ctx, level, fail, stream)

    message(ctx, target, definition, effect)

    if effect.special then
        special(ctx, target, definition, effect, amount,
            stream)

        return true
    end

    local profile = {
        flavour = effect.flavour,
        rng_stream = stream,
    }

    if school == schools.EARTH then
        amount = beam_damage.armour(ctx, amount,
            defense.armour(ctx, target, definition), profile)
    end

    amount = beam_damage.resisted(ctx, target, amount, profile)
    side_effect(ctx, target, definition, source, school,
        amount, stream)

    if ctx:get(target, "core.health").current > 0 then
        magic_damage.apply(ctx, target, amount, source)
    end

    return true
end

return miscast
