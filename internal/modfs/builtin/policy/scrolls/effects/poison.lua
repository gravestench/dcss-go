-- Source: spl-clouds.cc:scroll_of_poison fills open visible cells.
local cloud = require("policy.clouds.placement")
local cloud_ids = require("ids.clouds")
local component = require("constants.component")
local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")
local zap_ids = require("policy.magic.effects.zaps.ids")

local effect = {}
local SIGHT_RADIUS = 7

-- Collect visible unoccupied cells without clouds before allocating new poison clouds.
local function open_cells(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local cells = {}

    for y = origin.y - SIGHT_RADIUS, origin.y + SIGHT_RADIUS do
        for x = origin.x - SIGHT_RADIUS, origin.x + SIGHT_RADIUS do
            if ctx:walkable(origin.level_id, x, y) and
                not ctx:actor_at(origin.level_id, x, y) and
                not cloud.at(ctx, origin.level_id, x, y) and
                ctx:visible(origin.level_id, origin.x, origin.y,
                    SIGHT_RADIUS, x, y) then
                cells[#cells + 1] = {
                    level_id = origin.level_id,
                    x = x,
                    y = y,
                }
            end
        end
    end

    return cells
end

-- A known scroll warns if no open visible cell can hold a cloud.
function effect.prepare(ctx, player, request)
    if request.known and #open_cells(ctx, player) == 0 then
        return {
            message = "There's no open space to fill with poison.",
        }
    end

    return nil
end

-- Example: Poison chooses open cells and a spell-stream cloud duration before placement.
-- Draw each cloud duration on the spell stream after the candidate cells are fixed.
function effect.apply(ctx, player)
    local cells = open_cells(ctx, player)

    for _, cell in ipairs(cells) do
        local duration = (10 + ctx:random("spell", 11)) * 10

        cloud.place(ctx, cloud_ids.CLOUD_POISON, player,
            cell.level_id, cell.x, cell.y, duration)
    end

    if #cells > 0 then
        ctx:emit("read", "The air fills with toxic fumes!")
    else
        ctx:emit("read", "Nothing happens.")
    end
end

scrolls.register(item_ids.SCR_POISON, effect)

return effect
