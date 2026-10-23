-- A high-level Abyss teleport can force descent. This fixture fixes only
-- the source chance draw, leaving the production branch-depth rule intact.
local abyss = require("policy.world.abyss")
local component = require("constants.component")
local constants = require("constants.abyss")
local harness = require("tests.harness")

local test = {}

-- The descent call is observed without creating a full terrain fixture;
-- live tests separately exercise region replacement and save replay.
function test.run()
    local player = {}
    local descended = false
    local original = abyss.descend
    local ctx = {}

    function ctx:session_state(name)
        harness.equal(name, constants.SESSION_STATE)

        return { branch_depth = 1 }
    end

    function ctx:get(entity, name)
        harness.equal(entity, player)

        if name == component.POSITION then
            return { level_id = constants.LEVEL_ID }
        end

        if name == component.PROGRESSION then
            return { level = 27 }
        end
    end

    function ctx:random(_, bound)
        harness.equal(bound, 729 * 3)

        return 0
    end

    abyss.descend = function(_, actor)
        harness.equal(actor, player)
        descended = true
    end

    local okay, reason = pcall(abyss.teleport, ctx, player)

    abyss.descend = original

    if not okay then
        error(reason)
    end

    harness.truthy(descended)
end

return test
