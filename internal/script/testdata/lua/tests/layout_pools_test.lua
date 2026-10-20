-- Pool growth is shared map policy: source layouts choose materials while
-- this module keeps neighboring pools separated by traversable borders.
local grid = require("policy.generation.grid")
local pools = require("policy.generation.layouts.pools")
local harness = require("tests.harness")

local test = {}

-- A varied deterministic source exercises frontier order through the same
-- unbiased builder draw that live layout generation uses.
local function random_context()
    local state = 31
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "pool layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- With one possible material, every assigned pool must paint lava while
-- some floor remains between separate pools and at the immutable rim.
local function grows_separated_pools()
    local builder = grid.new(random_context())

    for y = 10, 30 do
        for x = 10, 40 do
            builder:set(x, y, ".")
        end
    end

    local count = pools.add(builder, 18, {
        { glyph = "l", weight = 1 },
    })
    local lava = 0
    local floor = 0

    for y = 10, 30 do
        for x = 10, 40 do
            local glyph = builder:cell(x, y)

            if glyph == "l" then
                lava = lava + 1
            elseif glyph == "." then
                floor = floor + 1
            end
        end
    end

    harness.truthy(count > 1, "multiple source pool seeds")
    harness.truthy(lava > 0, "liquid pool cells")
    harness.truthy(floor > 0, "separating floor cells")
    harness.equal(builder:cell(0, 0), "#", "outer rim retained")
end

-- Exercise the shared algorithm apart from a cave's later cleanup passes.
function test.run()
    grows_separated_pools()
end

return test
