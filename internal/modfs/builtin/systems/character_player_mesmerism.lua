-- Theory of operation: each player action ages the one saved beholder state
-- and prunes sources that no longer see or can sing to the player. This
-- precedes regeneration but follows general duration handling.
-- Example: a dead siren is removed on the player's next action, starting
-- a short immunity before another siren may enthrall the player.
local component = require("constants.component")
local mesmerism = require("policy.character.player_mesmerism")

local system = {}

-- The active query prevents monster actions from consuming the player's
-- mesmerism timer; `delta` is the player's actual action cost in aut.
function system.update(ctx, actor, delta)
    if actor == ctx:player() then
        mesmerism.tick(ctx, actor, delta)
    end
end

register.system({
    id = "character.player_mesmerism.tick",
    scope = "active",
    query = { component.PLAYER_MESMERISM },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
