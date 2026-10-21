-- Each Swamp ending must survive the production DES transform and fit path;
-- parsing the files alone cannot prove their rune and monster intent resolves.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local effects = require("constants.vault_effects")
local end_vault = require("policy.generation.vaults.primary")
local extra = require("policy.generation.vaults.extra")
local availability = require("policy.generation.floor_availability")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local items = require("ids.items")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Supply the real layout stream and a connected floor, with a distinct
-- sequence for every source map so rare substitutions get varied draws.
local function floor_for(seed)
    local state = seed
    local ctx = {}

    function ctx:random_u64()
        state = (state * 48271) % 2147483647
        local hi = state

        state = (state * 48271) % 2147483647

        return hi, state
    end

    local builder = grid.new(ctx)

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    return ctx, builder
end

-- Count the typed item requests that game materialization turns into ECS
-- rune entities; a MAP glyph by itself does not prove a live rune exists.
local function rune_count(records)
    local count = 0

    for _, record in ipairs(records) do
        if record.kind == effects.ITEM and record.arguments and
            record.arguments.kind_id == items.RUNE_SWAMP then
            count = count + 1
        end
    end

    return count
end

-- Fit all eleven definitions and check the branch-level required pool.
function test.run()
    vaults.load()

    local branch = register.get(categories.BRANCHES, branches.BRANCH_SWAMP)
    local count = 0

    harness.equal(end_vault.specification(branch, branch.depth).family,
        "swamp_end",
        "Swamp declares its end family")
    harness.truthy(end_vault.specification(branch, branch.depth),
        "Swamp requires its authored ending")
    harness.truthy(availability.can_build(branches.BRANCH_SWAMP, 4),
        "source end pool opens Swamp:4")

    local candidates = end_vault.candidates({
        branch_id = branches.BRANCH_SWAMP,
        depth = 4,
        branch_bottom = 4,
        absolute_depth = 18,
        primary_vault_family = "swamp_end",
    })

    harness.equal(#candidates, 11,
        "all eleven source endings enter the weighted pool")

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local vault = vaults.get(id)

        if vault.family == "swamp_end" then
            count = count + 1

            -- Several independent source streams cover uncommon NSUBST and
            -- conditional rune/guardian outcomes without fixing one seed.
            for trial = 1, 4 do
                local ctx, builder = floor_for(count * 97 + trial + 113)
                local context = {
                    branch_id = branches.BRANCH_SWAMP,
                    depth = 4,
                    branch_bottom = 4,
                    absolute_depth = 18,
                    protected = {},
                    required = {},
                    player = {
                        branch_id = branches.BRANCH_SWAMP,
                        depth = 4,
                        branch_bottom = 4,
                        absolute_depth = 18,
                    },
                }
                local placed, reason = extra.place(ctx, builder,
                    vault, context)

                harness.truthy(placed, id .. " placed: " .. tostring(reason))
                harness.equal(placed.id, id, "source identity")
                harness.equal(rune_count(placed.records), 1,
                    id .. " has exactly one real rune")
            end
        end
    end

    harness.equal(count, 11, "all source Swamp endings placed")
end

return test
