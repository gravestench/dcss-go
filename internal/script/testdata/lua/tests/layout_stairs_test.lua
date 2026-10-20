-- Shared stair completion uses the actual Dungeon grid owner, so layout
-- authors do not need to redeclare the row or coordinate conventions.
local grid = require("policy.generation.grid")
local stairs = require("policy.generation.layouts.stairs")
local glyphs = require("constants.vault_glyphs")
local harness = require("tests.harness")

local test = {}

-- A deterministic layout stream exercises the production bounded draw
-- without a second mock implementation of grid:roll.
local function random_context()
    local state = 0
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "stair layout stream")
        state = state + 1

        return 0, state
    end

    return context
end

-- A source layout can carve terrain without authoring stairs; the postpass
-- must place all ordinary exits inside its connected playable region.
local function fills_missing_stairs()
    local builder = grid.new(random_context())

    for y = 10, 25 do
        for x = 10, 30 do
            builder:set(x, y, ".")
        end
    end

    local pairs = stairs.complete(builder)

    harness.equal(#pairs, 3, "three source stair pairs")

    for _, pair in ipairs(pairs) do
        harness.truthy(glyphs.up[builder:cell(pair.up.x, pair.up.y)],
            "up exit is a source stair")
        harness.truthy(glyphs.down[builder:cell(pair.down.x, pair.down.y)],
            "down exit is a source stair")
    end
end

-- Keep an authored exit and make only the missing counterpart. Source maps
-- with extra exits should not lose those cells during the generic postpass.
local function preserves_authored_stairs()
    local builder = grid.new(random_context())

    for y = 10, 25 do
        for x = 10, 30 do
            builder:set(x, y, ".")
        end
    end

    builder:set(12, 12, "{")
    builder:set(14, 12, "(")
    builder:set(12, 18, "}")

    local pairs = stairs.complete(builder)

    harness.equal(#pairs, 3, "missing stairs completed")
    harness.equal(builder:cell(12, 12), "{", "first authored up stair")
    harness.equal(builder:cell(14, 12), "(", "second authored up stair")
    harness.equal(builder:cell(12, 18), "}", "authored down stair")
end

-- A layout without enough connected floor must fail promptly, so mod
-- authors see a map error instead of a partial, unreachable game level.
local function rejects_insufficient_floor()
    local builder = grid.new(random_context())

    builder:set(10, 10, ".")
    builder:set(11, 10, ".")

    local ok = pcall(stairs.complete, builder)

    harness.falsy(ok, "two floor cells cannot hold three stair pairs")
end

-- Source cave layouts deliberately place down stairs in separate bubbles.
-- Each bubble needs a local return stair so a future branch floor can pair
-- it with a real parent departure without tunnelling through solid rock.
local function preserves_separate_stair_bubbles()
    local builder = grid.new(random_context())
    local centers = { 15, 35, 55 }

    for _, center in ipairs(centers) do
        for y = 10, 20 do
            for x = center - 5, center + 5 do
                builder:set(x, y, ".")
            end
        end

        builder:set(center, 15, "}")
    end

    builder:set(16, 15, "{")

    local pairs = stairs.complete(builder)

    harness.equal(#pairs, 3, "one stair pair per cave bubble")

    for _, pair in ipairs(pairs) do
        harness.truthy(math.abs(pair.up.x - pair.down.x) <= 5 and
            math.abs(pair.up.y - pair.down.y) <= 5,
            "a cave return stair stays in its down-stair bubble")
    end
end

-- A terminal branch floor keeps authored down exits as map facts, but the
-- engine must not manufacture a deeper level beyond the source branch depth.
local function branch_bottom_does_not_add_downstairs()
    local builder = grid.new(random_context())

    for y = 10, 25 do
        for x = 10, 30 do
            builder:set(x, y, ".")
        end
    end

    local pairs = stairs.complete(builder, {
        up = 1,
        down = 0,
    })

    harness.equal(#pairs, 1, "one branch return stair")
    harness.truthy(pairs[1].up, "branch return stair exists")
    harness.falsy(pairs[1].down, "no invented down stair")
end

-- Run both successful construction paths and the bounded failure case.
function test.run()
    fills_missing_stairs()
    preserves_authored_stairs()
    rejects_insufficient_floor()
    preserves_separate_stair_bubbles()
    branch_bottom_does_not_add_downstairs()
end

return test
