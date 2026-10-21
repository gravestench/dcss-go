-- A real Game calls this test policy through the production Lua runtime.
-- It changes the same saved worship component as later conduct actions,
-- allowing the Go test to compare post-restore RNG and piety exactly.
local component = require("constants.component")
local piety = require("policy.religion.piety")

local probe = {}

-- Configure a legal candidate state or spend source candidate points, then
-- return only the saved amount for an end-to-end deterministic comparison.
function probe.run(ctx, input)
    local player = ctx:player()
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if input.god_id then
        state.god_id = input.god_id
        state.piety = input.piety
        ctx:set(player, component.RELIGION_WORSHIP, state)
    end

    if input.numerator then
        piety.gain(ctx, player, input.numerator, input.denominator, false)
    end

    return {
        piety = ctx:get(player, component.RELIGION_WORSHIP).piety,
    }
end

register.policy({
    id = "test.religion_piety",
    run = probe.run,
})

return probe
