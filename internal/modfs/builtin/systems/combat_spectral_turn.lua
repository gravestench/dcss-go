local component = require("constants.component")
local summons = require("policy.magic.effects.summons.common")

local system = {}

-- Theory of operation: Uncommanded weapons expire and commanded ones react before constriction closes the turn.
-- Spectral summons act after combat but before constriction settles the turn.
function system.update(ctx, active)
    if active ~= ctx:player() then
        return
    end

    -- Source: main.cc. An uncommanded spectral weapon fades
    -- before ordinary monster decisions for the new player action.
    for _, ally in ipairs(ctx:query({ component.SPECTRAL_WEAPON })) do
        local state = ctx:get(ally, component.SPECTRAL_WEAPON)

        if state.triggered_aut ~= ctx:aut() then
            summons.expire(ctx, ally)
        end
    end
end

register.system({
    id = "combat.spectral_turn",
    scope = "active",
    query = {},
    after = { "attack.combat" },
    before = { "status.constriction" },
    update = system.update,
})

return system
