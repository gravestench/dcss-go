-- One duration owner ages temporary flight for player and monster actors.
-- The vortex can grant flight to a victim without retaining a timer for it.
local component = require("constants.component")
local flight = require("policy.combat.flight")
local zap_ids = require("policy.magic.effects.zaps.ids")

local system = {}

-- Theory of operation: every acting actor with temporary flight loses the
-- aut it spent. A monster that just cast Vortex keeps its full initial
-- flight duration until its next action, matching enchantment timing.
function system.update(ctx, actor, aut)
    if not ctx:has(actor, component.ZAP_FLIGHT) then
        return
    end

    if not ctx:has(actor, component.PLAYER) then
        local vortex = ctx:get(actor, zap_ids.component.POLAR_VORTEX)

        if vortex and vortex.started_aut == ctx:aut() then
            return
        end
    end

    flight.tick(ctx, actor, aut)
end

register.system({
    id = "combat.flight.tick",
    scope = "active",
    -- A spell or potion can grant flight earlier in this same action.
    -- An empty query lets the system see that newly staged component.
    query = {},
    after = { "attack.player_spell" },
    before = { "world.movement" },
    update = system.update,
})

return system
