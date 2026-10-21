-- Every active Pan map must execute its original declarations and named
-- hooks through production placement, even if an ordinary seed misses it.
local branches = require("ids.branches")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Give each map an independent seeded layout stream. File traversal does
-- not influence one map's choices or consume another map's random state.
local function random_context()
    local state = 83
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- A tagged fixed-rune map needs the controller's request tag. Choose its
-- real-rune tag here; the separate hook test checks the lure alternative.
local function request_tag(definition)
    for tag in pairs(definition.tags) do
        if tag:match("^pan_fixed_rune_") then
            return tag
        end
    end

    return nil
end

-- A portal replacing a floor cell needs an existing traversable floor.
-- Leave the immutable border rock while giving every independent map a
-- connected base on which its placement rules can be exercised.
local function open_baseline(builder)
    for y = 2, grid.height - 3 do
        for x = 2, grid.width - 3 do
            builder:set(x, y, ".")
        end
    end
end

-- A dummy contributes only to source weighted choice and has no useful
-- terrain to place. Every other map executes on a connected base grid.
local function place_one(id, is_entry)
    local definition = vaults.get(id)

    if definition.tags.dummy then
        harness.equal(id, "pan_mini_dummy_balancer",
            "only the source Pan mini balance placeholder is skipped")

        return false
    end

    local player = {
        branch_id = is_entry and branches.BRANCH_DEPTHS or
            branches.BRANCH_PANDEMONIUM,
        depth = is_entry and 2 or 1,
        branch_bottom = is_entry and 5 or 1,
        absolute_depth = is_entry and 22 or 24,
        map_tag = request_tag(definition),
        collected_runes = {},
        pan_rune_count = 0,
    }
    local builder = grid.new(random_context())

    open_baseline(builder)

    local okay, placed = pcall(placement.place,
        nil, builder, definition, player, {
            whole_level = not is_entry,
        })

    harness.truthy(okay, id .. " placement: " .. tostring(placed))
    harness.truthy(placed and #placed.occupied > 0,
        id .. " placed no source cells")

    return true
end

-- Place the full source family at its authored branch and depth, with
-- saved rune facts supplied in the same shape as live Pan generation.
function test.run()
    local count = 0

    for _, family in ipairs({ "pan_entry", "pan" }) do
        for _, path in ipairs(mod.paths("vaults/" .. family, ".des")) do
            local id = path:match("([^/]+)%.des$")

            if place_one(id, family == "pan_entry") then
                count = count + 1
            end
        end
    end

    harness.equal(count, 140,
        "every active Pan map except its no-placement dummy was placed")
end

return test
