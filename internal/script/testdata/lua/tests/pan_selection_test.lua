-- A Pan region always chooses a primary from the effective DES catalog.
-- These checks use production definitions so new mod files join the same
-- sorted pool without a second handwritten registry.
local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local harness = require("tests.harness")
local selector = require("policy.generation.pan.selection")
local tags = require("constants.vault_tags")

local test = {}

-- Make every draw visible: the source pressure roll must precede its lord
-- identity and weighted map draw, and a completed set skips pressure.
local function random(draws)
    local result = {
        index = 0,
    }

    function result:roll(bound)
        self.index = self.index + 1
        local value = draws[self.index]

        if value == nil or value < 0 or value >= bound then
            error("unexpected Pan selection draw " .. self.index)
        end

        return value
    end

    return result
end

-- Only non-extra, non-mini source maps compete to own the whole region.
-- Their stable IDs, rather than file traversal order, determine draw order.
local function check_primary_pool()
    local candidates = selector.candidates({})

    harness.truthy(#candidates > 0, "Pan needs a primary map")

    local previous = ""

    for _, candidate in ipairs(candidates) do
        local map = catalog.get(candidate.definition.id)

        harness.truthy(map.id > previous, "Pan primary IDs are sorted")
        harness.equal(map.family, "pan", "primary belongs to Pan")
        harness.falsy(map.tags.extra, "extra vault became primary")
        harness.falsy(map.tags.minivault, "minivault became primary")
        harness.falsy(map.tags.dummy, "dummy became primary")
        previous = map.id
    end
end

-- On the first region a successful one-in-twenty pressure roll selects
-- one of the four unseen lord families before the ordinary weighted pool.
local function check_lord_pressure()
    local source = random({ 0, 0, 0 })
    local map = selector.choose(source, {
        levels_seen = 0,
        prior_vault_ids = {},
    })

    harness.truthy(map.tags[tags.PAN_LORD_MNOLEG],
        "first unseen lord should be Mnoleg")
    harness.equal(source.index, 3, "pressure, lord, and map draws")

    local next_source = random({ 0, 1, 0 })
    local next_map = selector.choose(next_source, {
        levels_seen = 1,
        prior_vault_ids = { map.id },
    })

    harness.falsy(next_map.tags[tags.PAN_LORD_MNOLEG],
        "an already generated lord cannot return")
end

-- Once all four unique lord tags have appeared, skip the pressure and
-- identity draws. The ordinary sorted pool still supplies a primary.
local function check_completed_lords()
    local prior = {
        "mnoleg",
        "lom_lobon",
        "cerebov",
        "gloorx_vloq",
    }
    local source = random({ 0 })
    local map = selector.choose(source, {
        levels_seen = 12,
        prior_vault_ids = prior,
    })

    harness.truthy(map, "ordinary primary after all lords")
    harness.equal(source.index, 1, "completed lords need only one draw")
end

-- The branch ID is a shared constant, not a literal selector string.
function test.run()
    harness.truthy(branches.BRANCH_PANDEMONIUM, "Pan branch ID exists")
    catalog.load()
    check_primary_pool()
    check_lord_pressure()
    check_completed_lords()
end

return test
