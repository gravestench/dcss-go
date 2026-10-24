-- Phantom Mirror chooses a visible living actor, not a terrain cell.
local component = require("constants.component")
local harness = require("tests.harness")
local mirror = require("policy.inventory.evokers.phantom_mirror")

local test = {}

-- Empty cells and self-targets cancel before an action can spend XP debt.
function test.run()
    local player = {}
    local ctx = {}

    function ctx:get(entity, id)
        if entity == player and id == component.POSITION then
            return { level_id = 1, x = 3, y = 3 }
        end
    end

    function ctx:actor_at()
        return nil
    end

    harness.truthy(mirror.prepare(ctx, player, 1, 0))
    harness.truthy(mirror.prepare(ctx, player, 0, 0))
end

return test
