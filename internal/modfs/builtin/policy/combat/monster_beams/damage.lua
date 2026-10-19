local flavours = require("constants.beam_flavours")
local catalog = require("policy.catalog")
local component = require("constants.component")
local form_ids = require("constants.form_ids")
local holy = require("policy.clouds.effects.holy")
local magic_damage = require("policy.magic.damage")
local miasma = require("policy.clouds.effects.miasma")
local holiness = require("constants.monster_holiness")
local monster_poison = require("policy.combat.monster_poison")
local player_resistance = require("policy.combat.player_resistance")
local resistances = require("constants.resistance_ids")
local monsters = require("ids.monsters")
local undead_states = require("constants.undead_states")
local water = require("policy.combat.monster_beams.water")

local damage = {}

local elemental_resistance = {
    [flavours.BEAM_FIRE] = resistances.FIRE,
    [flavours.BEAM_COLD] = resistances.COLD,
    [flavours.BEAM_ICE] = resistances.COLD,
    [flavours.BEAM_LAVA] = resistances.FIRE,
    [flavours.BEAM_ELECTRICITY] = resistances.ELECTRICITY,
    [flavours.BEAM_STUN_BOLT] = resistances.ELECTRICITY,
    [flavours.BEAM_ACID] = resistances.ACID,
    [flavours.BEAM_STEAM] = resistances.STEAM,
    [flavours.BEAM_NEG] = resistances.NEGATIVE_ENERGY,
}

-- Source: fight.cc:get_resistible_fraction. The rest is impact damage.
local resistible_fraction = {
    [flavours.BEAM_ICE] = 40,
    [flavours.BEAM_LAVA] = 55,
    [flavours.BEAM_POISON_ARROW] = 70,
}

-- Poison beam damage uses the target's live resistance, independent of its poison status dose.
local function poison_resisted(ctx, target, raw, profile)
    local is_player = ctx:has(target, component.PLAYER)
    local level

    if is_player then
        level = player_resistance.poison(ctx, target)
    else
        local definition = magic_damage.monster(ctx, target)

        if not definition then
            error("poison beam target is not an actor")
        end

        level = monster_poison.resistance(definition)
    end

    local fraction = resistible_fraction[profile.flavour] or 100
    local resistible = math.floor(raw * fraction / 100)
    local irresistible = raw - resistible

    if level >= 3 then
        return irresistible
    end

    if level > 0 then
        local divisor

        if is_player then
            divisor = math.floor((3 * level + 1) / 2) + 1
        else
            divisor = 2 + level * level
        end

        resistible = math.floor(resistible / divisor)
    elseif level < 0 then
        resistible = math.floor(resistible * 15 / 10)
    end

    return resistible + irresistible
end

-- Dispel Undead checks species or live form for players and holiness for monsters.
local function undead(ctx, target)
    if ctx:has(target, component.PLAYER) then
        local identity = ctx:get(target, component.PLAYER)
        local species = catalog.get("species", identity.species_id)
        local form = ctx:get(target, component.PLAYER_FORM)

        return species.undead_type == undead_states.UNDEAD or
            form and form.form_id == form_ids.LICH
    end

    local definition = magic_damage.monster(ctx, target)

    if not definition then
        error("dispel undead target is not an actor")
    end

    for _, kind in ipairs(definition.holiness or {}) do
        if kind == holiness.UNDEAD then
            return true
        end
    end

    return false
end

-- Example: damage.armour(ctx, raw, ac, profile) with BEAM_DAMNATION profile -> raw damage bypasses AC
-- Source: beam.cc:bolt::apply_AC. Beam armour does not use GDR.
function damage.armour(ctx, raw, ac, profile)
    if raw <= 0 or profile.flavour == flavours.BEAM_DAMNATION or
        profile.flavour == flavours.BEAM_DISPEL_UNDEAD then
        return raw
    end

    local saved = ctx:random("monster_spell", ac + 1)

    if profile.flavour == flavours.BEAM_ELECTRICITY then
        saved = math.floor(saved / 2)
    end

    return math.max(0, raw - saved)
end

-- Route each beam flavour through its own resistance rule after armour has been rolled.
function damage.resisted(ctx, target, raw, profile)
    if profile.flavour == flavours.BEAM_WATER then
        return water.damage(ctx, target, raw)
    end

    if profile.flavour == flavours.BEAM_MMISSILE then
        return raw
    end

    if profile.flavour == flavours.BEAM_DISPEL_UNDEAD then
        return undead(ctx, target) and raw or 0
    end

    if profile.flavour == flavours.BEAM_HOLY then
        if holy.immune(ctx, target) then
            return 0
        end

        return holy.adjust(ctx, target, raw)
    end

    if profile.flavour == flavours.BEAM_MIASMA then
        return miasma.immune(ctx, target) and 0 or raw
    end

    if profile.flavour == flavours.BEAM_CRYSTAL then
        -- beam.cc:bolt::fake_flavour chooses fire or cold per crystal hit.
        local element = ctx:random("monster_spell", 2) == 0 and
            resistances.FIRE or resistances.COLD

        if ctx:has(target, component.PLAYER) then
            return magic_damage.player_elemental(ctx, target,
                raw, element)
        end

        return magic_damage.monster_elemental(ctx, target,
            raw, element)
    end

    if profile.flavour == flavours.BEAM_DAMNATION then
        if ctx:has(target, component.PLAYER) then
            return raw
        end

        local definition = magic_damage.monster(ctx, target)

        if not definition then
            error("damnation target is not an actor")
        end

        for _, entry in ipairs(definition.resistances or {}) do
            if entry.id == resistances.DAMNATION and entry.level > 0 then
                return 0
            end
        end

        return raw
    end

    if profile.flavour == flavours.BEAM_DEVASTATION then
        if ctx:has(target, component.PLAYER) then
            return raw
        end

        local actor = ctx:get(target, component.ACTOR)

        if not actor then
            error("devastation target is not an actor")
        end

        -- beam.cc:bolt::nasty_to excludes orbs of destruction.
        if actor.kind_id == monsters.MONS_ORB_OF_DESTRUCTION then
            return 0
        end

        return raw
    end

    if profile.flavour == flavours.BEAM_POISON or
        profile.flavour == flavours.BEAM_POISON_ARROW then
        return poison_resisted(ctx, target, raw, profile)
    end

    local resistance_id = elemental_resistance[profile.flavour]

    if not resistance_id then
        error("monster beam flavor has no resistance policy: " ..
            tostring(profile.flavour))
    end

    local fraction = resistible_fraction[profile.flavour] or 100
    local resistible = math.floor(raw * fraction / 100)
    local irresistible = raw - resistible

    if ctx:has(target, component.PLAYER) then
        return irresistible + magic_damage.player_elemental(ctx,
            target, resistible, resistance_id)
    end

    return irresistible + magic_damage.monster_elemental(ctx, target,
        resistible, resistance_id)
end

return damage
