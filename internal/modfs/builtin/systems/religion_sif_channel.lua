-- Theory of operation: once a completed player action has advanced time,
-- Channel Magic converts that action's aut into MP and ages its saved timer.
local channel = require("policy.religion.sif_muna.channel")
local component = require("constants.component")

local system = {}

-- Monster actions never advance the player's channelling timer.
function system.update(ctx, entity, elapsed_aut)
    if ctx:has(entity, component.PLAYER) then
        channel.tick(ctx, entity, elapsed_aut)
    end
end

register.system({
    id = "religion.sif_channel",
    scope = "active",
    query = {},
    after = { "attack.player_ability", "status.regeneration" },
    update = system.update,
})

return system
