-- Theory of operation: only completed player actions advance the echo;
-- a monster turn never shortens it or calls a beast on the player's behalf.
local effect = require("policy.combat.monster_spells.doom_howl")
local ids = require("policy.combat.monster_doom_howl.ids")

local system = {}

-- Advance the saved countdown before regeneration finishes the player turn.
function system.update(ctx, player, elapsed_aut)
    effect.tick(ctx, player, elapsed_aut)
end

register.system({
    id = "combat.player_doom_howl.tick",
    scope = "active",
    query = { ids.PLAYER_DOOM_HOWL },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
