-- Parsing a Tomb map is insufficient: source hooks, helper selection, and
-- monster/item names must all survive the same placement path as gameplay.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local families = require("constants.vault_families")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- A deterministic layout stream makes failed maps reproducible by ID.
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

-- Source family, not a filename prefix, decides the map's placement floor.
local function floor_for(definition)
    if definition.family == families.TOMB_ENTRY then
        return branches.BRANCH_CRYPT, 3, 21
    end

    if definition.family == families.TOMB_1 or
        definition.family == families.TOMB_1_CENTRE or
        definition.family == families.TOMB_1_HALL_STAIRS then
        return branches.BRANCH_TOMB, 1, 21
    end

    if definition.family == families.TOMB_2 or
        definition.family == families.TOMB_2_AMBUSH then
        return branches.BRANCH_TOMB, 2, 22
    end

    return branches.BRANCH_TOMB, 3, 23
end

-- Every effective Tomb map exercises its real hook and child placement.
function test.run()
    vaults.load()

    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family:match("^tomb_") then
            local branch_id, depth, absolute = floor_for(definition)
            local player = {
                branch_id = branch_id,
                depth = depth,
                branch_bottom = 3,
                absolute_depth = absolute,
                settings = {
                    guardian_counts = {
                        0,
                        0,
                        0,
                    },
                },
            }
            local placed = placement.place(nil,
                grid.new(random_context()), definition, player)

            harness.equal(placed.id, id, id .. " lost its map identity")
            count = count + 1
        end
    end

    harness.equal(count, 31, "all active Tomb definitions placed")
end

return test
