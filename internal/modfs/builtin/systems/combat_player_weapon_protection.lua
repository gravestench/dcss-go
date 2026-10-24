-- Theory of operation: qualifying Protection hits refresh a saved aura
-- during combat; completed player actions age it before regeneration.
local component = require("constants.component")
local protection = require("policy.combat.player_weapon_protection")

local system = {}

-- Only the player's elapsed action time ages this player-owned aura.
function system.update(ctx, actor, aut)
    protection.tick(ctx, actor, aut)
end

register.system({
    id = "combat.player_weapon_protection.tick",
    scope = "active",
    query = { component.PLAYER, component.WEAPON_PROTECTION },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
