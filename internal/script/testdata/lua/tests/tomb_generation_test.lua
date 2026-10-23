-- Tomb's named hatches require three concrete floors before the player
-- enters; this checks the Lua builder's complete transaction payload.
local branches = require("ids.branches")
local harness = require("tests.harness")
local levels = require("policy.generation.branch_levels")
local maps = require("ids.tomb_maps")
local availability = require("policy.generation.floor_availability")
local branch_entry = require("policy.generation.vaults.branch_entry")

local test = {}

-- Replayable layout draws keep failures tied to the Tomb builder, not a
-- random source seed or the order in which other tests loaded maps.
local function random_context(seed)
    local state = seed or 71
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    -- Trap and ambient-monster policies draw from named streams through
    -- this same test context, just as the live Lua context does.
    function context:random(_, bound)
        state = (state * 48271) % 2147483647

        return state % bound
    end

    return context
end

-- The bundle declares every level and cross-floor stair in one policy
-- result, with no pending hatch left for a later generator call.
function test.run()
    harness.truthy(availability.can_build(branches.BRANCH_TOMB, 1),
        "Tomb opens when its source maps exist")
    harness.equal(#branch_entry.candidates(branches.BRANCH_TOMB, {
        branch_id = branches.BRANCH_CRYPT,
        depth = 3,
        branch_bottom = 3,
        absolute_depth = 21,
    }), 10, "all Crypt-side Tomb entries are eligible")

    local tomb = require("policy.generation.tomb.level")
    local result = tomb.generate(random_context(), {
        branch_id = branches.BRANCH_TOMB,
        local_depth = 1,
        level_id = levels.id(branches.BRANCH_TOMB, 1),
        from_x = 10,
        from_y = 10,
        parent = {
            id = levels.id(branches.BRANCH_CRYPT, 3),
            branch_id = branches.BRANCH_CRYPT,
            local_depth = 3,
        },
        prior_vault_ids = {},
    })

    harness.equal(#result.levels, 3, "all Tomb floors staged together")

    for depth, level in ipairs(result.levels) do
        harness.equal(level.id, levels.id(branches.BRANCH_TOMB, depth))
        harness.equal(level.branch_id, branches.BRANCH_TOMB)
        harness.equal(level.local_depth, depth)
        harness.equal(#level.cells, 70, "whole source map height")
        harness.truthy(#level.stairs > 0, "source route has stair links")
    end

    harness.truthy(#result.parent_links > 0, "Crypt gate is resolved")
    harness.truthy(result.entry.x >= 0, "entry has a final coordinate")

    -- Probe multiple layout streams so helper variants must all retain a
    -- complete named route after source substitutions and transforms.
    local seen = {}

    for seed = 1, 2 do
        local variant = tomb.generate(random_context(seed), {
            branch_id = branches.BRANCH_TOMB,
            local_depth = 1,
            level_id = levels.id(branches.BRANCH_TOMB, 1),
            from_x = 10,
            from_y = 10,
            parent = {
                id = levels.id(branches.BRANCH_CRYPT, 3),
            },
        })

        for _, level in ipairs(variant.levels) do
            for _, id in ipairs(level.vault_ids) do
                seen[id] = true
            end
        end
    end

    harness.truthy(seen[maps.FIRST], "source Tomb:1 was selected")
    harness.truthy(seen[maps.THIRD], "source Tomb:3 was selected")
end

return test
