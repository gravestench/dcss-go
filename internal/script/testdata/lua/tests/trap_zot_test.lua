local harness = require("tests.harness")
local zot = require("policy.traps.zot.catalog")

local test = {}

function test.run()
    local rows = zot.outcomes()
    local total = 0
    local seen = {}

    harness.equal(#rows, 10, "source Zot table has ten outcomes")

    for _, row in ipairs(rows) do
        harness.falsy(seen[row.id], "Zot outcome IDs are unique")
        harness.truthy(row.weight > 0, "Zot outcome weight is positive")
        harness.truthy(type(require(row.module).apply) == "function",
            "Zot outcome has executable Lua policy")
        seen[row.id] = true
        total = total + row.weight
    end

    harness.equal(total, 24, "source Zot weights sum to 24")

    local offset = 0

    for _, row in ipairs(rows) do
        for draw = offset, offset + row.weight - 1 do
            local ctx = {}

            function ctx:random(_, bound)
                harness.equal(bound, total, "Zot table draw bound")

                return draw
            end

            harness.equal(zot.choose(ctx).id, row.id,
                "weighted Zot boundary " .. draw)
        end

        offset = offset + row.weight
    end
end

return test
