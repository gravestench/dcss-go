-- A Tomb is a group of saved temporary walls. This system releases the
-- group when its center empties or source duration expires.
local component = require("constants.component")

local system = {}

-- A broken wall stays broken; only a still-standing temporary rock wall
-- receives its recorded original feature when the Tomb group ends.
local function restore(ctx, marker)
    local wall = ctx:get(marker, component.TEMPORARY_TERRAIN)

    if not wall then
        return false
    end

    if ctx:cell(wall.level_id, wall.x, wall.y) ==
        wall.changed_feature then
        ctx:set_cell(wall.level_id, wall.x, wall.y,
            wall.original_feature)
    end

    ctx:destroy(marker)

    return true
end

-- Run before generic terrain expiry so each wall is restored once. A moved
-- player ends the group immediately, as timed-effects.cc:_drop_tomb does.
function system.update(ctx)
    for _, marker in ipairs(ctx:query({
        component.RELIGION_CARD_TOMB,
    })) do
        local tomb = ctx:get(marker, component.RELIGION_CARD_TOMB)
        local position = ctx:get(tomb.owner, component.POSITION)
        local occupied = position and
            position.level_id == tomb.level_id and
            position.x == tomb.x and position.y == tomb.y
        local expired = ctx:aut() >= tomb.expires_aut

        if not occupied or expired then
            local restored = 0

            for _, wall_marker in ipairs(tomb.wall_markers) do
                if restore(ctx, wall_marker) then
                    restored = restored + 1
                end
            end

            ctx:destroy(marker)

            if restored > 0 then
                local suffix = expired and "" or " prematurely"

                ctx:emit("religion", "The walls disappear" .. suffix .. "!")
            end
        end
    end
end

register.system({
    id = "religion.card_tomb",
    scope = "active",
    query = {},
    before = { "world.temporary_terrain" },
    update = system.update,
})

return system
