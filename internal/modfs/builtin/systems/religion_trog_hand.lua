-- Theory of operation: Trog's Hand ages on player action time before
-- regeneration samples the timer. No Go status switch owns this rule.
local component = require("constants.component")
local hand = require("policy.religion.trog.hand")

local system = {}

-- An active player Hand is the only entity requiring this tick.
function system.update(ctx, player, aut)
    if player == ctx:player() then
        hand.tick(ctx, player, aut)
    end
end

register.system({
    id = "religion.trog_hand.tick",
    scope = "active",
    query = { component.RELIGION_TROG_HAND },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
