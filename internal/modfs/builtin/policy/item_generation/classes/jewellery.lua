local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")
local ids = require("ids.items")
local pool = require("policy.item_generation.pool")
local source = require("policy.item_generation.source_roll")

local policy = {}

local stat_rings = {
    [ids.RING_STRENGTH] = true,
    [ids.RING_DEXTERITY] = true,
    [ids.RING_INTELLIGENCE] = true,
}

function policy.eligible(_, definition, request)
    if definition.class ~= classes.OBJ_JEWELLERY then
        return false
    end

    if request.kind_id == definition.id then
        return definition.generation.mode ~= "none"
    end

    if definition.generation.mode ~= "random" then
        return false
    end

    local amulet = definition.id:match("^AMU_") ~= nil

    return request.amulet == amulet
end

function policy.weight(_, definition)
    return definition.generation.weight or 1
end

function policy.pick(ctx, request)
    local selected = {}

    for key, value in pairs(request) do
        selected[key] = value
    end

    -- Source: makeitem.cc:1606-1607. One quarter of jewellery is an amulet.
    if selected.amulet == nil then
        selected.amulet = source.chance(ctx, 1, 4)
    end

    local result = pool.select(ctx, classes.OBJ_JEWELLERY, selected, policy)

    -- Source: makeitem.cc:2030-2036. Slaying gets two more chances to reroll.
    if result.id == ids.RING_SLAYING and not source.chance(ctx, 1, 3) then
        result = pool.select(ctx, classes.OBJ_JEWELLERY, selected, policy)
    end

    return result
end

function policy.roll(_, definition, _, result)
    if definition.jewellery and definition.jewellery.pluses then
        result.plus = stat_rings[definition.id] and 6 or 4
    end
end

catalog.register(classes.OBJ_JEWELLERY, policy)

return policy
