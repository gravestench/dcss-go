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

-- Run both successful construction paths and the bounded failure case.
function test.run()
    fills_missing_stairs()
    preserves_authored_stairs()
    rejects_insufficient_floor()
end

return test
