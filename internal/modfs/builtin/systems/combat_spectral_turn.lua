local component = require("constants.component")
local summons = require("policy.magic.effects.summons.common")

local system = {}

function system.update(ctx, active)
    if active ~= ctx:player() then
        return
    end

    -- Source: main.cc:2518-2524. An uncommanded spectral weapon fades
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
