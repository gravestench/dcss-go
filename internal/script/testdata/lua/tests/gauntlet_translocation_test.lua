-- The source seal blocks long-range travel, including mutation-driven
-- teleportitis. A blink remains a local move and must still be allowed.
local branches = require("ids.branches")
local component = require("constants.component")
local golubria = require("policy.magic.effects.translocation.golubria")
local harness = require("tests.harness")
local teleportitis = require("policy.mutations.effects.teleportitis")
local translocation = require("policy.scrolls.translocation")

local test = {}

-- Give the production policies only their normal context reads. Any
-- mutation RNG draw inside Gauntlet is an error even when it changes no cell.
local function context(branch_id)
    local mock = {}

    function mock:get(_, key)
        if key == component.POSITION then
            return {
                level_id = 3601,
                x = 10,
                y = 10,
            }
        end

        if key == component.PLAYER then
            return { species_id = "SP_HUMAN" }
        end

        return nil
    end

    function mock:level_branch()
        return branch_id
    end

    function mock:random()
        error("Gauntlet restriction spent random state")
    end

    return mock
end

-- The `blinking` argument is intentional: source no_tele_reason uses
-- it to distinguish local blink from long-range teleport requests.
function test.run()
    local sealed = context(branches.BRANCH_GAUNTLET)
    local reason = translocation.restriction(sealed, 1, false)

    harness.truthy(reason and
        reason:find("Gauntlet", 1, true),
        "long-range Gauntlet teleport was allowed")
    harness.equal(translocation.restriction(sealed, 1, true), nil,
        "Gauntlet blink was sealed")
    harness.equal(translocation.restriction(
        context(branches.BRANCH_DUNGEON), 1, false), nil,
        "outside long-range teleport was sealed")

    teleportitis.tick(sealed, 1, 10)
    harness.equal(golubria.prepare(sealed, 1, nil, 1, 0),
        "A magic seal in the Gauntlet prevents you from opening a passage!",
        "Passage of Golubria ignored the Gauntlet seal")
end

return test
