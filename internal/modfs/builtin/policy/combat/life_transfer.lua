-- Negative-energy life transfer is shared by monster Vampiric Draining,
-- Drain Life, and Malign Offering. These spells choose different targets and
-- recipients, while this owner keeps victim resistance and HP writes alike.
-- Source: mon-util.cc:actor_is_susceptible_to_vampirism, beam.cc.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local form_ids = require("constants.form_ids")
local holiness = require("constants.monster_holiness")
local player_holiness = require("policy.character.holiness")
local monster_drain = require("policy.combat.monster_drain")
local monster_profile = require("policy.combat.monster_profile")
local monster_health = require("policy.combat.monster_health")
local player_health = require("policy.combat.player_health")
local damage = require("policy.magic.damage")
local resistances = require("constants.resistance_ids")
local species_ids = require("ids.species")

local transfer = {}

-- Search an imported source enum in a definition list without relying on
-- the order of content files or the presence of optional fields.
local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Player holiness changes with species blood state and Lich Form. A
-- semi-undead vampire is drainable only while its live blood state is alive.
local function player_living(ctx, player)
    return player_holiness.natural(ctx, player)
end

-- Source actor holiness makes Gargoyles, Djinn, and petrified actors
-- nonliving. Keep this narrower than the undead check used by life theft.
local function player_nonliving(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local form = ctx:get(player, component.PLAYER_FORM)
    local petrification = ctx:get(player,
        component.PLAYER_PETRIFICATION)

    return identity.species_id == species_ids.SP_GARGOYLE or
        identity.species_id == species_ids.SP_DJINNI or
        form and (form.form_id == form_ids.WISP or
            form.form_id == form_ids.STORM) or
        petrification and petrification.petrified_aut > 0
end

-- Malign Offering heals every aligned actor except the nonliving, even an
-- undead or demonic ally. Vampiric extraction has stricter eligibility.
function transfer.offering_recipient(ctx, victim)
    if ctx:has(victim, component.PLAYER) then
        return not player_nonliving(ctx, victim)
    end

    local actor = ctx:get(victim, component.ACTOR)
    local definition = monster_profile.definition(ctx, victim,
        catalog.get(categories.MONSTERS, actor.kind_id))

    return not contains(definition.holiness, holiness.NONLIVING)
end

-- Ordinary life theft is limited to natural or plant holiness for monsters.
function transfer.living(ctx, victim)
    if ctx:has(victim, component.PLAYER) then
        return player_living(ctx, victim)
    end

    local actor = ctx:get(victim, component.ACTOR)
    local definition = monster_profile.definition(ctx, victim,
        catalog.get(categories.MONSTERS, actor.kind_id))

    return contains(definition.holiness, holiness.NATURAL) or
        contains(definition.holiness, holiness.PLANT)
end

-- Source excludes summoned, spectral, and firewood monsters from vampiric
-- extraction, even when they still have an ordinary health component.
function transfer.susceptible(ctx, victim)
    if not transfer.living(ctx, victim) or
        ctx:has(victim, component.SUMMON) or
        ctx:has(victim, component.SPECTRAL_WEAPON) then
        return false
    end

    if ctx:has(victim, component.PLAYER) then
        return true
    end

    local actor = ctx:get(victim, component.ACTOR)
    local definition = monster_profile.definition(ctx, victim,
        catalog.get(categories.MONSTERS, actor.kind_id))
    local firewood = definition.speed == 0 and
        contains(definition.flags, flags.NO_THREAT)

    return not firewood
end

-- Both sides use their live rN owner, so equipment and forms can change
-- resistance without changing a static monster or species definition.
function transfer.resistance(ctx, victim)
    if ctx:has(victim, component.PLAYER) then
        return damage.player_resistance(ctx, victim,
            resistances.NEGATIVE_ENERGY)
    end

    local actor = ctx:get(victim, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    return monster_drain.resistance(ctx, victim, definition)
end

-- Player rN quarters at two pips; monster rN follows its own stronger
-- 1/(1+rN^2) scale. Both sides are immune at three pips.
function transfer.resisted(raw, level, is_monster)
    if level >= 3 then
        return 0
    end

    if level > 0 then
        if is_monster then
            return math.floor(raw / (1 + level * level))
        end

        return math.floor(raw / (2 * level))
    end

    if level < 0 then
        return math.floor(raw * 3 / 2)
    end

    return raw
end

-- Send the resisted loss through the victim's health owner and return the
-- actual HP removed. Heal amounts must use dealt HP, not a raw dice roll.
function transfer.hurt(ctx, source, victim, raw)
    local is_monster = not ctx:has(victim, component.PLAYER)
    local amount = transfer.resisted(raw,
        transfer.resistance(ctx, victim), is_monster)

    if amount <= 0 then
        return 0
    end

    local _, dealt

    if not is_monster then
        _, dealt = player_health.damage(ctx, victim,
            amount, false, source)
    else
        _, dealt = monster_health.damage(ctx, victim, amount, source)
    end

    return dealt
end

-- All life-transfer recipients keep HP on the entity. Player Death's Door
-- can forbid healing; monsters use the ordinary maximum-HP cap.
function transfer.heal(ctx, recipient, amount)
    if amount <= 0 or
        (ctx:has(recipient, component.PLAYER) and
            not player_health.can_heal(ctx, recipient)) then
        return 0
    end

    local health = ctx:get(recipient, component.HEALTH)
    local before = health.current

    if before <= 0 then
        return 0
    end

    health.current = math.min(health.max, before + amount)
    ctx:set(recipient, component.HEALTH, health)

    return health.current - before
end

return transfer
