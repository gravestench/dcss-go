-- Source: crawl-ref/source/acquire.cc:_acquirement_jewellery_subtype and
-- _acquirement_staff_subtype.
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local jewellery_kinds = require("constants.jewellery_kind")
local selection = require("policy.scrolls.acquirement.selection")
local source = require("policy.item_generation.source_roll")

local accessories = {}

local function candidates(class_id, predicate)
    local rows = {}

    for _, kind in ipairs(catalog.all("items")) do
        if kind.class == class_id and kind.generation.mode == "random" and
            predicate(kind) then
            rows[#rows + 1] = {
                id = kind.id,
                weight = kind.generation.weight or 1,
            }
        end
    end

    return rows
end

function accessories.jewellery(ctx, player)
    local amulet = source.chance(ctx, 1, 3)
    local rows = candidates(classes.OBJ_JEWELLERY, function(kind)
        return (kind.jewellery.kind == jewellery_kinds.AMULET) == amulet
    end)

    -- The source retries known jewellery up to ten times.
    local chosen

    for _ = 1, 10 do
        chosen = selection.weighted(ctx, rows)

        if not selection.seen(ctx, player, chosen) then
            break
        end
    end

    return chosen
end

function accessories.staff(ctx, player)
    local rows = candidates(classes.OBJ_STAVES, function(kind)
        return kind.staff ~= nil
    end)
    local weighted = {}
    local total = 0

    for _, row in ipairs(rows) do
        local kind = catalog.get("items", row.id)
        local skill_id = kind.staff.skill_id
        local level = skill_id and selection.skill(ctx, skill_id) or 0

        if not selection.seen(ctx, player, kind.id) and level > 0 then
            weighted[#weighted + 1] = {
                id = kind.id,
                weight = level,
            }
            total = total + level
        end
    end

    -- Source adds a five-weight uniform fallback among all active staves.
    if source.chance(ctx, 5, 5 + total) or #weighted == 0 then
        return selection.weighted(ctx, rows)
    end

    return selection.weighted(ctx, weighted)
end

return accessories
