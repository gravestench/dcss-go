-- Source monster requests can ask for a depth beyond a branch's last floor.
-- Each exceptional branch keeps its source cap in its own catalog record;
-- the resolver uses physical depth only for branches without an exception.
local categories = require("constants.catalog")
local branches = require("ids.branches")
local harness = require("tests.harness")

local test = {}

-- A smaller cap silently changes the population eligible for source DES
-- requests such as 8, 9, and place:D:N, even if the vault still places.
function test.run()
    local source_caps = {
        {
            id = branches.BRANCH_DUNGEON,
            cap = 27,
        },
        {
            id = branches.BRANCH_COCYTUS,
            cap = 14,
        },
        {
            id = branches.BRANCH_GEHENNA,
            cap = 14,
        },
        {
            id = branches.BRANCH_TARTARUS,
            cap = 14,
        },
        {
            id = branches.BRANCH_DIS,
            cap = 14,
        },
        {
            id = branches.BRANCH_DEPTHS,
            cap = 13,
        },
        {
            id = branches.BRANCH_VAULTS,
            cap = 12,
        },
        {
            id = branches.BRANCH_LAIR,
            cap = 12,
        },
        {
            id = branches.BRANCH_ELF,
            cap = 7,
        },
        {
            id = branches.BRANCH_SWAMP,
            cap = 7,
        },
        {
            id = branches.BRANCH_SPIDER,
            cap = 7,
        },
        {
            id = branches.BRANCH_CRYPT,
            cap = 5,
        },
        {
            id = branches.BRANCH_TOMB,
            cap = 5,
        },
    }

    for _, source in ipairs(source_caps) do
        local definition = register.get(categories.BRANCHES, source.id)

        harness.equal(definition.ood_cap, source.cap,
            source.id .. " source out-of-depth cap")
    end

    local snake = register.get(categories.BRANCHES, branches.BRANCH_SNAKE)

    harness.equal(snake.ood_cap or snake.depth, 4,
        "Snake uses its source physical depth as the default cap")
end

return test
