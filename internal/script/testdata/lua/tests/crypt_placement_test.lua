-- Every committed Crypt definition must survive the production operation
-- engine, including hook expansion, source choices, and typed records.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local families = require("constants.vault_families")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Each map gets a fresh reproducible stream, so placement does not depend
-- on which other files a mod added or on catalog iteration order.
local function random_context()
    local state = 41
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- Select a valid branch floor for this source family. Crypt:1 arrivals are
-- tested at their own depth, while other ordinary maps use Crypt:2.
local function floor_for(definition)
    if definition.family == families.CRYPT_ENTRY then
        return branches.BRANCH_VAULTS, 3, 5, 16
    end

    if definition.family == families.CRYPT_END then
        return branches.BRANCH_CRYPT, 3, 3, 21
    end

    local depth = definition.id:match("^grunt_crypt_arrival_") and 1 or 2

    return branches.BRANCH_CRYPT, depth, 3, 19 + depth - 1
end

-- A successful local placement proves more than parser acceptance: all
-- emitted directives must resolve against the live monster/item catalogs.
function test.run()
    vaults.load()

    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if
            definition.family == families.CRYPT_ENTRY
            or definition.family == families.CRYPT
            or definition.family == families.CRYPT_END
        then
            local branch_id, depth, bottom, absolute = floor_for(definition)
            local player = {
                branch_id = branch_id,
                depth = depth,
                branch_bottom = bottom,
                absolute_depth = absolute,
            }
            local placed = placement.place(
                nil,
                grid.new(random_context()),
                definition,
                player
            )

            harness.equal(placed.id, id, id .. " lost its authored identity")
            count = count + 1
        end
    end

    harness.equal(count, 59, "all source Crypt definitions placed")
end

return test
