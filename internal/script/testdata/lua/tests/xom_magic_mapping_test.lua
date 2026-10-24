-- Xom's mapping is a powered area reveal, not the unlimited scroll effect.
-- It writes terrain memory through the same saved grid command as other maps.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local event_ids = require("ids.xom_events")
local branches = require("ids.branches")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")

local test = {}

-- A tiny Dungeon floor lies entirely within a severity-50 mapping radius.
-- Zero difficulty rolls reveal every cell, and each cell is requested once.
function test.run(ctx)
    local player = ctx:create()
    local mapped = {}
    local draws = 0
    local proxy = setmetatable({}, { __index = ctx })

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    -- The test grid is small; all lasting map writes use the production
    -- map_cell method, represented here by its requested coordinates.
    function proxy:level_size()
        return 3, 3
    end

    -- Dungeon has a persistent map; unmappable branches are tested by
    -- the generic map policy rather than copying branch flags here.
    function proxy:level_branch()
        return branches.BRANCH_DUNGEON
    end

    -- Zero is an allowed result for every source mapping draw and makes
    -- the nine-cell expectation independent of draw iteration order.
    function proxy:random(stream, bound)
        draws = draws + 1
        harness.equal(stream, streams.RELIGION)

        if draws == 1 then
            harness.equal(bound, 50)
        elseif draws == 2 then
            harness.equal(bound, 51)
        end

        return 0
    end

    -- Record the actual map command requests so a narration-only effect
    -- would fail this test even if it emitted the expected speech.
    function proxy:map_cell(_, x, y)
        mapped[y * 3 + x + 1] = true

        return true
    end

    events.apply(proxy, player, event_ids.GOOD_MAGIC_MAPPING, 50, {
        stream = streams.RELIGION,
    })

    for index = 1, 9 do
        harness.truthy(mapped[index], "Xom left a reachable cell unknown")
    end
end

return test
