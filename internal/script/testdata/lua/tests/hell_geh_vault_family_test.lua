-- Gehenna's ordinary maps and lava maze helpers are committed source assets.
-- Loading every one through the real DES pipeline catches broken named hooks.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Keep draws reproducible while each definition gets an independent grid.
local function random_context()
    local state = 109
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state
        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- The source ordinary Gehenna file has thirty maps, while lava-maze maps
-- hold one controller and thirty-eight separately discoverable helpers.
function test.run()
    vaults.load()

    local counts = {
        geh = 0,
        geh_lava_maze = 0,
        hells = 0,
    }
    local player = {
        branch_id = branches.BRANCH_GEHENNA,
        depth = 2,
        branch_bottom = 7,
        absolute_depth = 25,
    }

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if counts[definition.family] then
            counts[definition.family] = counts[definition.family] + 1

            local placed = placement.place(nil,
                grid.new(random_context()), definition, player)

            harness.equal(placed.id, id,
                "Gehenna source map keeps its authored identity")
        end
    end

    harness.equal(counts.geh, 30, "ordinary Gehenna map count")
    harness.equal(counts.geh_lava_maze, 39,
        "Gehenna lava maze controller and helper count")
    harness.equal(counts.hells, 10, "shared Hell source map count")
end

return test
