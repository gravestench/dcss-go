-- Shared monster-status fixtures use production ECS schemas and override
-- only grid/time services absent from the isolated Lua rule test host.
local component = require("constants.component")

local fixture = {}

-- Make a real ECS actor with the components used by source target checks.
-- Tests supply kind and placement, so they do not redeclare catalog facts.
function fixture.actor(ctx, kind_id, x, y, hp)
    local entity = ctx:create()

    ctx:add(entity, component.ACTOR, {
        kind_id = kind_id,
        speed = 10,
    })
    ctx:add(entity, component.POSITION, {
        level_id = 1,
        x = x,
        y = y,
    })
    ctx:add(entity, component.HEALTH, {
        current = hp,
        max = hp,
    })

    return entity
end

-- Keep real ECS access while giving area policies a clear test level.
-- The production grid still owns actual visibility during a game.
function fixture.context(ctx, player, now)
    local live = setmetatable({}, { __index = ctx })

    -- Allegiance asks for the player handle even for monster-only effects.
    function live:player()
        return player
    end

    -- A clear line allows status eligibility without a Go level fixture.
    function live:visible()
        return true
    end

    -- Source LOS_NO_TRANS ignores intervening actors but stops at walls.
    function live:visible_no_trans()
        return true
    end

    -- Abjuration and status expiry compare against the saved aut clock.
    function live:aut()
        return now or 0
    end

    return live
end

return fixture
