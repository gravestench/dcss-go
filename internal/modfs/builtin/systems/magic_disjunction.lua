local disjunction = require("policy.magic.effects.translocation.disjunction")

local system = {}

-- Theory of operation: The pulse mutates nearby positions after casting and before status durations age.
-- Disjunction pulses after casting and before the player's status durations tick.
function system.update(ctx, actor, aut)
    if actor == ctx:player() then
        disjunction.pulse(ctx, actor, aut)
    end
end

register.system({
    id = "magic.disjunction.pulse",
    scope = "active",
    query = {},
    after = { "attack.player_spell" },
    before = { "magic.player_status.tick" },
    update = system.update,
})

return system
