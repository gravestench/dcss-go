-- Every source ending must survive the production DES transform, entity
-- resolver, and connector path. A catalog parse alone cannot prove that.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local effects = require("constants.vault_effects")
local directives = require("constants.vault_directives")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local items = require("ids.items")
local extra = require("policy.generation.vaults.extra")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Give each end map an ordinary connected floor and independent layout
-- stream. The source map, not this fixture, decides its terrain and actors.
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

-- The typed source record is retained after pickup, so count it rather
-- than looking for a transient rune glyph in the rendered terrain.
local function rune_count(records)
    local count = 0

    for _, record in ipairs(records) do
        if record.kind == effects.ITEM and record.arguments and
            record.arguments.kind_id == items.RUNE_SNAKE then
            count = count + 1
        end
    end

    return count
end

-- Fit the entire source family, including uncommon substitution outcomes.
function test.run()
    vaults.load()

    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local vault = vaults.get(id)

        if vault.family == "snake_end" then
            count = count + 1

            local ctx, builder = floor_for(count + 31)
            local context = {
                branch_id = branches.BRANCH_SNAKE,
                depth = 4,
                branch_bottom = 4,
                absolute_depth = 18,
                protected = {},
                required = {},
                player = {
                    branch_id = branches.BRANCH_SNAKE,
                    depth = 4,
                    branch_bottom = 4,
                    absolute_depth = 18,
                },
            }
            local placed, reason = extra.place(ctx, builder, vault,
                context)

            harness.truthy(placed, id .. " placed: " .. tostring(reason))
            harness.equal(placed.id, id, "source identity")
            harness.equal(rune_count(placed.records), 1,
                id .. " has exactly one real rune")
        end
    end

    harness.equal(count, 9, "all source end maps placed")

    local hunt = vaults.get("snake_hunt")
    local disconnected = {}

    for key, value in pairs(hunt) do
        disconnected[key] = value
    end

    disconnected.rows = { "{xxxO" }
    disconnected.operations = {}

    for _, operation in ipairs(hunt.operations) do
        if operation.kind == directives.HOOK_VALIDATE then
            disconnected.operations[1] = operation
        end
    end

    local bad_ctx, bad_builder = floor_for(47)
    local bad_context = {
        branch_id = branches.BRANCH_SNAKE,
        depth = 4,
        branch_bottom = 4,
        absolute_depth = 18,
        protected = {},
        required = {},
        player = {
            branch_id = branches.BRANCH_SNAKE,
            depth = 4,
            branch_bottom = 4,
            absolute_depth = 18,
        },
    }
    local rejected = extra.place(bad_ctx, bad_builder, disconnected,
        bad_context)

    harness.falsy(rejected,
        "source hunt validator rejects a disconnected rune")

    local ctx, builder = floor_for(61)
    local generated, primary, history = extra.generate(ctx, builder, {
        branch_id = branches.BRANCH_SNAKE,
        depth = 4,
        branch_bottom = 4,
        absolute_depth = 18,
        primary_vault_family = "snake_end",
        layout_family = "rooms",
        protected = {},
        required = {},
        prior_vault_ids = {},
        player = {
            branch_id = branches.BRANCH_SNAKE,
            depth = 4,
            branch_bottom = 4,
            absolute_depth = 18,
        },
    })

    harness.truthy(generated[1], "mandatory end precedes extras")
    harness.equal(generated[1].family, "snake_end",
        "first extra is required Snake end")
    harness.equal(primary, generated[1].id,
        "end map is the floor's primary vault")
    harness.equal(history[1], primary, "end map enters save history")
end

return test
