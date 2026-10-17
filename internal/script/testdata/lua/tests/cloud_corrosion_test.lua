local harness = require("tests.harness")
local component = require("constants.component")

local test = {}

function test.run()
    local corrosion = require("policy.combat.player_corrosion")
    local state = {
        remaining_aut = 120,
        stacks = 2,
    }
    local ctx = {}

    function ctx:get(_, kind)
        harness.equal(kind, component.CORROSION,
            "corrosion reads its production schema")

        return state
    end

    harness.equal(corrosion.penalty(ctx, 1), 8,
        "two active stacks remove eight AC and attack damage")

    state.remaining_aut = 0
    harness.equal(corrosion.penalty(ctx, 1), 0,
        "expired corrosion has no penalty")
end

return test
