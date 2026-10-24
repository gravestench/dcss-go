-- These probes call production formulas and selectors. They do not copy
-- an item schema or define a second implementation of the source rules.
local chessboard = require("policy.inventory.evokers.xoms_chessboard")
local condenser = require("policy.inventory.evokers.condenser_vane")
local ids = require("constants.evoker_chessboard")
local harness = require("tests.harness")
local targets = require("policy.inventory.evokers.targets")
local tin = require("policy.inventory.evokers.tin_of_tremorstones")
local clouds = require("ids.clouds")

local test = {}

-- A chosen roll is enough to test weighted boundaries without rebuilding
-- the weights inside the test fixture.
local function chooser(roll)
    local ctx = {}

    function ctx:random(_, bound)
        harness.truthy(roll < bound)

        return roll
    end

    return ctx
end

-- Spot-check source count endpoints, cloud progression, ten chessboard
-- moves, and the free blind-use confirmation decision.
function test.run()
    harness.equal(tin.explosion_count(0), 1)
    harness.equal(tin.explosion_count(27), 6)
    harness.equal(condenser.choose_cloud(chooser(0), 15),
        clouds.CLOUD_MEPHITIC)
    harness.equal(condenser.choose_cloud(chooser(0), 70),
        clouds.CLOUD_FIRE)

    local boundaries = {
        { roll = 0, id = ids.HASTE },
        { roll = 5, id = ids.INVISIBILITY },
        { roll = 10, id = ids.MIGHT },
        { roll = 15, id = ids.CORONA },
        { roll = 25, id = ids.SLOW },
        { roll = 40, id = ids.MALMUTATE },
        { roll = 55, id = ids.PETRIFY },
        { roll = 70, id = ids.PARALYSE },
        { roll = 80, id = ids.CONFUSE },
        { roll = 90, id = ids.SLEEP },
    }

    for _, boundary in ipairs(boundaries) do
        harness.equal(chessboard.pick(chooser(boundary.roll)).id,
            boundary.id)
    end

    local prompt = targets.warn_if_unseen(false, false,
        "Release anyway?")

    harness.equal(prompt.confirmation, "Release anyway?")
    harness.equal(targets.warn_if_unseen(false, true,
        "Release anyway?"), nil)
end

return test
