-- Source: item-use.cc and view.cc:magic_mapping(500, 100, false).
local branch_flags = require("constants.branch_flags")
local catalog = require("policy.catalog")
local component = require("constants.component")
local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")

local effect = {}

-- Check the branch NO_MAP flag so a known scroll can warn before consumption.
local function map_persistent(ctx, player)
    local position = ctx:get(player, component.POSITION)
    local branch_id = ctx:level_branch(position.level_id)
    local branch = catalog.get("branches", branch_id)

    for _, flag in ipairs(branch.flags) do
        if flag == branch_flags.NO_MAP then
            return false
        end
    end

    return true
end

-- Known scrolls decline in unmappable branches before issuing an action.
function effect.prepare(ctx, player, request)
    if request.known and not map_persistent(ctx, player) then
        return {
            message = "It would have no effect in this place.",
        }
    end

    return nil
end

-- Example: Magic Mapping marks every cell on the current mappable level as explored.
-- Map every cell only in persistent-map branches; otherwise emit the transient failure message.
function effect.apply(ctx, player)
    if not map_persistent(ctx, player) then
        ctx:emit("read", "You feel momentarily disoriented.")

        return
    end

    local position = ctx:get(player, component.POSITION)
    local width, height = ctx:level_size(position.level_id)

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            ctx:map_cell(position.level_id, x, y)
        end
    end

    ctx:emit("read", "You feel aware of your surroundings.")
end

scrolls.register(item_ids.SCR_MAGIC_MAPPING, effect)

return effect
