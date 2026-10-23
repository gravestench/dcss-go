-- Every source Ice Cave map must place through the production whole-floor
-- owner in both saved difficulty variants. This catches a hook that parses
-- but cannot populate a playable destination.
local branches = require("ids.branches")
local harness = require("tests.harness")
local terrain = require("constants.terrain")

local test = {}

-- A reproducible stream makes failures name the offending map and variant.
local function random_context()
    local state = 83
    local context = {}

    -- Supply the two-word stream used by the production grid builder.
    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    -- Bounded draws choose weighted layouts and keyed source alternatives.
    function context:random(_, bound)
        state = (state * 48271) % 2147483647

        return state % bound
    end

    return context
end

-- The two variants reuse the same map ID but must carry their own source
-- records and provide an arrival on the authored return feature.
function test.run()
    local level = require("policy.generation.ice_cave.level")
    local maps = level.candidates({})

    harness.equal(#maps, 11, "source Ice Cave child count")

    for _, map in ipairs(maps) do
        for _, hard in ipairs({ false, true }) do
            local generated = level.generate(random_context(), {
                hard = hard,
                layout_id = map.id,
                species_id = "SP_HUMAN",
                player_name = "Tester",
            })
            local floor = generated.level
            local row = floor.cells[floor.entry_y + 1]

            harness.equal(floor.branch_id, branches.BRANCH_ICE_CAVE,
                map.id .. " branch")
            harness.equal(floor.vault_id, map.id,
                map.id .. " selected layout")
            harness.equal(row[floor.entry_x + 1],
                terrain.DNGN_EXIT_ICE_CAVE,
                map.id .. " safe return")
            harness.truthy(#floor.vault_records > 0,
                map.id .. " authored records")
        end
    end
end

return test
