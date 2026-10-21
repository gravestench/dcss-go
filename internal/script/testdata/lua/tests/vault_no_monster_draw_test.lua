-- A source branch pool may include an explicit no-monster outcome.
-- Vault random requests consume that draw without consulting a missing
-- monster definition or spawning a replacement species.
local branches = require("ids.branches")
local harness = require("tests.harness")
local pool = require("policy.population.pool")
local resolve = require("policy.generation.vaults.specs.resolve")
local sentinels = require("constants.population_sentinels")

local test = {}

-- Find the actual weighted sentinel row so this test follows the same
-- source table and draw interval as live Lair vault placement.
local function no_monster_draw()
    local rows = pool.at_depth(branches.BRANCH_LAIR, 4)
    local offset = 0

    for _, row in ipairs(rows) do
        if row.id == sentinels.NO_MONSTER then
            return offset
        end

        offset = offset + row.weight
    end
end

-- The resolver should return a no-spawn choice, not ask the catalog for
-- MONS_NO_MONSTER or silently redraw the placement RNG stream.
function test.run()
    local draw = no_monster_draw()

    harness.truthy(draw, "Lair source pool has no empty draw")

    local ctx = {
        draws = 0,
    }

    function ctx:random(_, bound)
        self.draws = self.draws + 1
        harness.truthy(draw < bound, "empty draw lies outside pool")

        return draw
    end

    local result = resolve.monster(ctx, {
        name = "random_monster",
    }, 4, {
        branch_id = branches.BRANCH_LAIR,
        local_depth = 4,
    })

    harness.truthy(result.no_spawn, "source empty draw spawned a monster")
    harness.equal(ctx.draws, 1, "empty draw was rerolled")
end

return test
