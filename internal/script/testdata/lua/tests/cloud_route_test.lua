-- Monster does not step into miasma.

local harness = require("tests.harness")
local component = require("constants.component")
local ids = require("ids.clouds")
local monsters = require("ids.monsters")

local test = {}

-- Route around miasma even when the direct route callback proposes the hazardous step.
function test.run()
    local route = require("policy.ai.route")
    -- Put miasma directly between the monster and its target, leaving an
    -- alternate first step for route.follow to choose.
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

    -- Keep the routed monster distinct from the player for danger checks.
    function ctx:player()
        return 99
    end

    -- Expose exactly the miasma cloud at the direct first step.
    function ctx:query()
        return { 17 }
    end

    -- Return cloud state for the queried entity and rat state for the mover.
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

    -- Leave visibility permissive so the cloud is the only route constraint.
    function ctx:visible()
        return true
    end

    -- Bound the miniature map while leaving alternate first steps open.
    function ctx:walkable(_, x, y)
        return x >= 0 and y >= 0 and x <= 4 and y <= 2
    end

    -- Keep alternative cells unoccupied to test cloud avoidance alone.
    function ctx:actor_at()
        return nil
    end

    -- Propose the shortest step through miasma and require follow to reject it.
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
