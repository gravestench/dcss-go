-- The source theft vault asks for monsters from other branch rosters with
-- place:Branch, place:Branch:N, and place:Branch:$. Parsing those terms is
-- insufficient if the resolver then draws from the current Abyss roster.
local branches = require("ids.branches")
local harness = require("tests.harness")
local pool = require("policy.population.pool")
local random_monsters = require("policy.generation.vaults.specs.random_monsters")

local test = {}

-- Always choose the first weighted roster entry to expose the branch and
-- depth selected by the source place annotation without copying its rows.
local function first_pick(branch_id, depth)
    local choices, total = pool.at_depth(branch_id, depth)
    local context = {}

    function context:random()
        return 0
    end

    harness.truthy(total > 0, "expected branch population")

    return pool.pick(context, choices, total)
end

-- A branch alone means floor one; a dollar means its static branch bottom.
function test.run()
    local context = {}
    local site = {
        branch_id = branches.BRANCH_ABYSS,
        local_depth = 3,
    }

    function context:random()
        return 0
    end

    harness.equal(random_monsters.pick(context, "0", 3, site,
        "Lair:1"), first_pick(branches.BRANCH_LAIR, 1))
    harness.equal(random_monsters.pick(context, "0", 3, site,
        "Lair:$"), first_pick(branches.BRANCH_LAIR, 5))
    harness.equal(random_monsters.pick(context, "0", 3, site,
        "Slime"), first_pick(branches.BRANCH_SLIME, 1))
end

return test
