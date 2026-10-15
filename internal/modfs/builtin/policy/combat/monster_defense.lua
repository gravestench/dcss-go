-- A monster's current defenses include effects stored on its ECS entity.
-- Source: monster.cc:melee_evasion and armour_class.
local equipment = require("policy.combat.equipment")
local component = require("constants.component")
local size = require("constants.size")
local monster_stats = require("policy.combat.monster_stats")

local defense = {}

function defense.evasion(ctx, monster, definition)
    local ev = definition.ev or 0
    local clutch = ctx:get(monster, component.MONSTER_VILE_CLUTCH)
    local roots = ctx:get(monster, component.GRASPING_ROOTS)
    local grip = ctx:get(monster, component.PLAYER_CONSTRICTION)

    if clutch and clutch.remaining_aut > 0 or
        roots and roots.remaining_aut > 0 or grip then
        local divisor = (size.rank[definition.size_id] or 3) + 2
        ev = math.floor(ev / divisor)
    end

    return math.max(0, ev)
end

function defense.armour(ctx, monster, definition)
    local ac = (definition.ac or 0) +
        equipment.protection_ac(ctx, monster)
    local wretched = ctx:get(monster, component.WRETCHED)

    if wretched and wretched.remaining_aut > 0 then
        ac = ac - 8
    end

    return math.max(0, ac)
end

function defense.shield(ctx, monster, definition)
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
    }
end

function defense.register_block(ctx, monster)
    local combat = ctx:get(monster, component.COMBAT)

    if not combat then
        error("blocking monster has no combat state")
    end

    combat.shield_blocks = combat.shield_blocks + 1
    ctx:set(monster, component.COMBAT, combat)

    return combat.shield_blocks
end

return defense
