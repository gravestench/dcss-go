local harness = require("tests.harness")
local component = require("constants.component")
local ids = require("ids.clouds")
local monsters = require("ids.monsters")

local test = {}

function test.run()
    local route = require("policy.ai.route")
    local position = {
        level_id = 1,
        x = 1,
        y = 1,
    }
    local destination = {
        level_id = 1,
        x = 3,
        y = 1,
    }
    local state = {
        target_x = 3,
        target_y = 1,
    }
    local cloud = {
        kind_id = ids.CLOUD_MIASMA,
        level_id = 1,
        x = 2,
        y = 1,
    }
    local ctx = {}

    function ctx:player()
        return 99
    end

    function ctx:query()
        return { 17 }
    end

    function ctx:get(entity, kind)
        if entity == 17 then
            return cloud
        end

        if kind == component.ACTOR then
            return { kind_id = monsters.MONS_RAT }
        end

        if kind == component.HEALTH then
            return { current = 5, max = 5 }
        end

        if kind == component.POSITION then
            return position
        end
    end

    function ctx:visible()
        return true
    end

    function ctx:walkable(_, x, y)
        return x >= 0 and y >= 0 and x <= 4 and y <= 2
    end

    function ctx:actor_at()
        return nil
    end

    function ctx:route_step()
        return 1, 0, true
    end

    local intent = route.follow(ctx, 1, state, position,
        destination, nil, true)

    harness.equal(intent.kind, 1,
        "monster can move around the dangerous cloud")
    harness.falsy(intent.dx == 1 and intent.dy == 0,
        "monster does not step into miasma")
end

return test
