local component = require("constants.component")
local kind = require("constants.target_kind")
local roll = require("policy.combat.roll")
local habitat = require("policy.combat.monster_habitat")

local target = {}

-- A foe-centered cast records a cell, not a live handle. If the foe moves
-- before resolution, the saved intent still points at the original cell.
function target.plan(ctx, caster, foe)
    if not foe then
        return nil
    end

    local caster_pos = ctx:get(caster, component.POSITION)
    local foe_pos = ctx:get(foe, component.POSITION)

    if not caster_pos or not foe_pos or
        caster_pos.level_id ~= foe_pos.level_id then
        return nil
    end

    return {
        kind = kind.CELL,
        entity = foe,
        level_id = foe_pos.level_id,
        x = foe_pos.x,
        y = foe_pos.y,
    }
end

-- A later resolver may use only the planned cell on the caster's level.
-- This rejects an entity plan and an intent rewritten to another level.
function target.require_cell(ctx, caster, plan)
    local position = ctx:get(caster, component.POSITION)

    if not plan or plan.kind ~= kind.CELL or
        not position or plan.level_id ~= position.level_id then
        error("monster summon target differs from planned cell")
    end

    return plan
end

-- Mushrooms first try all adjacent cells around the planned victim, then
-- the outer radius-two ring. Randomize each ring's start without depending
-- on hash traversal or moving the anchor when the foe moves.
function target.open_spot(ctx, plan, kind_id)
    for radius = 1, 2 do
        local cells = {}

        for dy = -radius, radius do
            for dx = -radius, radius do
                if math.max(math.abs(dx), math.abs(dy)) == radius then
                    cells[#cells + 1] = {
                        x = plan.x + dx,
                        y = plan.y + dy,
                    }
                end
            end
        end

        local start = roll.spell(ctx, #cells) + 1

        for offset = 0, #cells - 1 do
            local cell = cells[(start + offset - 1) % #cells + 1]

            if habitat.kind_at(ctx, kind_id, plan.level_id,
                cell.x, cell.y) and
                not ctx:actor_at(plan.level_id, cell.x, cell.y) then
                return cell.x, cell.y
            end
        end
    end

    return nil, nil
end

return target
