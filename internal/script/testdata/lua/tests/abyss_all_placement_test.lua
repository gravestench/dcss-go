-- Parser acceptance alone cannot prove that an authored Abyss room works.
-- Resolve every non-dummy map through the production placement path so its
-- keyed features, monsters, items, and named hooks are exercised together.
local branches = require("ids.branches")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Each map receives its own stream; discovery order cannot affect choices.
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

-- A source minivault needs traversable cells around its local rectangle.
-- This keeps the test about vault semantics rather than one layout seed.
local function open_baseline(builder)
    for y = 2, grid.height - 3 do
        for x = 2, grid.width - 3 do
            builder:set(x, y, ".")
        end
    end
end

-- The entry group is authored for Depths while the other definitions use
-- the mutable Abyss depth. Supply the same player facts as live placement.
local function place_one(path, is_entry)
    local id = path:match("([^/]+)%.des$")
    local definition = vaults.get(id)

    if definition.tags.dummy then
        return false
    end

    local builder = grid.new(random_context())
    local player = {
        branch_id = is_entry and branches.BRANCH_DEPTHS or
            branches.BRANCH_ABYSS,
        depth = is_entry and 3 or 3,
        branch_bottom = is_entry and 4 or 7,
        absolute_depth = is_entry and 24 or 25,
        settings = {
            wu_jian_available = true,
        },
    }

    open_baseline(builder)

    local okay, placed = pcall(placement.place,
        nil, builder, definition, player)

    harness.truthy(okay, id .. " placement: " .. tostring(placed))
    harness.truthy(placed and #placed.occupied > 0,
        id .. " placed no source cells")

    return true
end

-- Dummies are deliberate null choices, so only the 97 MAP blocks place.
function test.run()
    local count = 0

    for _, family in ipairs({ "abyss_entry", "abyss" }) do
        for _, path in ipairs(mod.paths("vaults/" .. family, ".des")) do
            if place_one(path, family == "abyss_entry") then
                count = count + 1
            end
        end
    end

    harness.equal(count, 97, "all source Abyss maps placed")
end

return test
