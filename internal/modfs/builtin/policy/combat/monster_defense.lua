-- A monster's current defenses include effects stored on its ECS entity.
-- Source: monster.cc:melee_evasion and armour_class.
local equipment = require("policy.combat.equipment")
local component = require("constants.component")
local armour_egos = require("constants.armour_egos")
local size = require("constants.size")
local monster_stats = require("policy.combat.monster_stats")
local monster_profile = require("policy.combat.monster_profile")
local chaos_status = require("policy.combat.monster_target_brands.chaos_status")
local roll = require("policy.combat.roll")

local defense = {}

-- Reduce catalog EV while roots, clutch, or constriction hold the monster in place.
function defense.evasion(ctx, monster, definition)
    definition = monster_profile.definition(ctx, monster, definition)

    local ev = definition.ev or 0
    local clutch = ctx:get(monster, component.MONSTER_VILE_CLUTCH)
    local roots = ctx:get(monster, component.GRASPING_ROOTS)
    local grip = ctx:get(monster, component.PLAYER_CONSTRICTION)

    if clutch and clutch.remaining_aut > 0 or
        roots and roots.remaining_aut > 0 or grip or
        ctx:has(monster, component.CONSTRICTION) then
        local divisor = (size.rank[definition.size_id] or 3) + 2
        ev = math.floor(ev / divisor)
    end

    return math.max(0, chaos_status.evasion(ctx, monster, ev))
end

-- Combine innate AC with equipped protection, then apply active wretchedness.
function defense.armour(ctx, monster, definition)
    definition = monster_profile.definition(ctx, monster, definition)

    local ac = (definition.ac or 0) +
        equipment.protection_ac(ctx, monster)
    local wretched = ctx:get(monster, component.WRETCHED)

    if wretched and wretched.remaining_aut > 0 then
        ac = ac - 8
    end

    return math.max(0, ac)
end

-- A monster unable to respond cannot raise a shield despite wearing one.
local function incapacitated(ctx, monster)
    local paralysis = ctx:get(monster, component.PARALYSIS)
    local stasis = ctx:get(monster, component.MONSTER_STASIS)
    local confusion = ctx:get(monster, component.MONSTER_CONFUSION)

    return paralysis and paralysis.remaining_aut > 0 or
        stasis and (stasis.hibernating or stasis.petrified_aut > 0) or
        confusion and confusion.remaining_aut > 0 or
        ctx:has(monster, component.HELD)
end

-- Build an active shield profile only after checking control and equipment state.
function defense.shield(ctx, monster, definition)
    if incapacitated(ctx, monster) then
        return nil
    end

    local shield = equipment.monster_shield(ctx, monster)

    if not shield then
        return nil
    end

    local combat = ctx:get(monster, component.COMBAT)

    if not combat then
        error("shielded monster has no combat state")
    end

    return {
        ac = shield.definition.armour.ac,
        plus = shield.item.plus,
        subtype = shield.definition.subtype_value,
        size = definition.size_id,
        hit_dice = monster_stats.hit_dice(ctx, monster, definition),
        blocks = combat.shield_blocks,
        name = shield.definition.name,
        reflects = shield.ego == armour_egos.REFLECTION,
    }
end

-- Example: defense.register_block(ctx, monster) with one successful block -> shield_blocks increases by one
-- Increase the monster's block count so later shield contests become harder in this exchange.
function defense.register_block(ctx, monster)
    local combat = ctx:get(monster, component.COMBAT)

    if not combat then
        error("blocking monster has no combat state")
    end

    combat.shield_blocks = combat.shield_blocks + 1
    ctx:set(monster, component.COMBAT, combat)

    return combat.shield_blocks
end

-- Source: beam.cc and monster.cc. A returning beam
-- makes a fresh block roll against the original shooter's shield.
function defense.beam_block(ctx, shield, to_hit)
    local body_size = size.rank[shield.size]

    if not body_size then
        error("unsupported monster shield body size " ..
            tostring(shield.size))
    end

    local base = (shield.ac + shield.plus * 2) * 2 +
        (body_size - size.rank[size.MEDIUM]) *
        (shield.subtype - 14)
    local bound = base + math.floor(shield.hit_dice * 4 / 3)

    if bound <= 0 then
        return false
    end

    local shield_roll = roll.average_two(ctx, "monster_spell", bound)
    local bonus = math.floor(shield_roll / 2)

    if bonus <= 0 then
        return false
    end

    local bypass = math.floor(to_hit * 130 / 100) +
        4 * shield.blocks * shield.blocks
    local bypass_roll = roll.spell(ctx, bypass)

    return bypass_roll < bonus
end

return defense
