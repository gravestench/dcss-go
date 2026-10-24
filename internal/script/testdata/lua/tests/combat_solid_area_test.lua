-- A source LOS_SOLID radius includes the first wall surface but excludes
-- what that wall hides. Both divine blood and holy word import this policy.
local area = require("policy.combat.solid_area")
local harness = require("tests.harness")

local test = {}

-- The fixture supplies only the generic dense-grid reads used by the
-- production trajectory; no alternate ray algorithm lives in the test.
function test.run()
    local grid = {}

    function grid:walkable(_, x, y)
        return x >= 1 and y >= 1 and x <= 7 and y <= 7 and x ~= 4
    end

    function grid:actor_at()
        return nil
    end

    local origin = { level_id = 1, x = 2, y = 3 }

    harness.truthy(area.contains(grid, origin,
        { level_id = 1, x = 3, y = 3 }, 3))
    harness.truthy(area.contains(grid, origin,
        { level_id = 1, x = 4, y = 3 }, 3))
    harness.falsy(area.contains(grid, origin,
        { level_id = 1, x = 5, y = 3 }, 3))
    harness.falsy(area.contains(grid, origin,
        { level_id = 2, x = 3, y = 3 }, 3))
end

return test
