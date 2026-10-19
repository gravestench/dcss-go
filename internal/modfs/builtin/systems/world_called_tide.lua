-- Called Shoals tide follows its caster and wets reachable shore cells.
-- The temporary terrain owner restores each touched floor when the call ends.
local component = require("constants.component")
local spells = require("ids.spells")
local temporary = require("policy.world.temporary_terrain")
local terrain = require("constants.terrain")

local system = {}
local STATE = "world.called_tide"
local RADIUS = 8

-- Source tide propagates from water and never creates water in an isolated
-- room. The current grid lacks Shoals heightmap metadata, so wet shoreline
-- is the supported cell-level expression of the called tide.
local function touches_water(ctx, level_id, x, y)
    for dy = -1, 1 do
        for dx = -1, 1 do
            local feature = ctx:cell(level_id, x + dx, y + dy)

            if feature == terrain.DNGN_SHALLOW_WATER or
                feature == terrain.DNGN_DEEP_WATER then
                return true
            end
        end
    end

    return false
end

function system.update(ctx, caster)
    local state = ctx:get(caster, STATE)

    if not state then
        return
    end

    if ctx:aut() >= state.expires_aut then
        ctx:remove(caster, STATE)
        return
    end

    local position = ctx:get(caster, component.POSITION)

    if not position then
        return
    end

    for _, cell in ipairs(ctx:visible_cells(position.level_id,
        position.x, position.y, RADIUS)) do
        local distance = math.max(math.abs(cell.x - position.x),
            math.abs(cell.y - position.y))

        if distance <= RADIUS and
            ctx:cell(position.level_id, cell.x, cell.y) == terrain.DNGN_FLOOR and
            touches_water(ctx, position.level_id, cell.x, cell.y) then
            temporary.place(ctx, caster, spells.SPELL_CALL_TIDE,
                position.level_id, cell.x, cell.y,
                terrain.DNGN_SHALLOW_WATER,
                state.expires_aut - ctx:aut())
        end
    end
end

register.system({
    id = "world.called_tide.tick",
    scope = "active",
    query = { STATE },
    before = { "monster.decision" },
    update = system.update,
})

return system
