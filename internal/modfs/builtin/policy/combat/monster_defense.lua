-- A monster's current defenses include effects stored on its ECS entity.
-- Source: monster.cc:melee_evasion and armour_class.
local equipment = require("policy.combat.equipment")
local component = require("constants.component")

local defense = {}

local size_rank = {
    SIZE_TINY = 0,
    SIZE_LITTLE = 1,
    SIZE_SMALL = 2,
    SIZE_MEDIUM = 3,
    SIZE_LARGE = 4,
    SIZE_GIANT = 5,
}

function defense.evasion(ctx, monster, definition)
    local ev = definition.ev or 0
    local clutch = ctx:get(monster, component.MONSTER_VILE_CLUTCH)
    local roots = ctx:get(monster, component.GRASPING_ROOTS)

    if clutch and clutch.remaining_aut > 0 or
        roots and roots.remaining_aut > 0 then
        local divisor = (size_rank[definition.size_id] or 3) + 2
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

return defense
