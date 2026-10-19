local catalog = require("policy.catalog")
local harness = require("tests.harness")
local polymorph = require("policy.magic.effects.statuses.polymorph")

local fixture = {}

-- Find a real source-legal species so tests can control unrelated RNG rolls
-- without copying the content catalog or relying on its first registered ID.
function fixture.stable_draw(game, kind_id, x, y, avoid_kind_id)
    local source = catalog.get("monsters", kind_id)
    local position = { level_id = 1, x = x, y = y }
    local pool = polymorph.shifter_pool(game, position)
    local selected

    for index, definition in ipairs(pool) do
        if definition.id ~= avoid_kind_id and
            polymorph.shifter_eligible(game, source, definition,
                position) and math.abs(definition.hd - source.hd) <= 1 then
            selected = index - 1
            break
        end
    end

    harness.truthy(selected, "fixture found a source-legal form")

    return function(_, _, bound)
        if bound == #pool then
            return selected
        end

        if bound == 200 then
            return 1
        end

        return 0
    end
end

return fixture
