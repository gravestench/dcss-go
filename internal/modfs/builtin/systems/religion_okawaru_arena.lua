-- The victory grace period ages on player time, like source duration
-- DUR_DUEL_COMPLETE. The forced-portal owner handles actual travel.
local component = require("constants.component")
local victory = require("policy.world.arena.victory")

local system = {}

-- Only the player can carry a Duel visit, even when a mod adds actors.
function system.update(ctx, player, aut)
    if player == ctx:player() then
        victory.tick(ctx, player, aut)
    end
end

register.system({
    id = "religion.okawaru_arena.tick",
    scope = "active",
    query = { component.PLAYER_ARENA_VISIT },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
