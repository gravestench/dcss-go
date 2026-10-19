-- The source monster enchant pulses before each later action, then decays.
-- Keeping that order here lets the last positive timer deliver its pulse.
local component = require("constants.component")
local radiance = require("policy.combat.monster_area.toxic_radiance")
local senses = require("policy.character.senses")
local display = require("policy.combat.monster_support.display")
local channels = require("constants.message_channels")

local system = {}

-- Theory of operation: the scheduler selects the acting caster by its saved
-- aura component. The aura sees its current grid cell and living enemies;
-- the timer then loses this action's aut before AI selects another spell.
function system.update(ctx, caster, delta)
    local state = ctx:get(caster, component.MONSTER_TOXIC_RADIANCE)

    if not state then
        return
    end

    radiance.pulse(ctx, caster, state.power)
    state.remaining_aut = state.remaining_aut - delta

    if state.remaining_aut <= 0 then
        ctx:remove(caster, component.MONSTER_TOXIC_RADIANCE)

        if senses.player_sees_actor(ctx, caster) then
            ctx:emit(channels.DURATION,
                "The " .. display.name(ctx, caster) ..
                    "'s toxic aura wanes.")
        end

        return
    end

    ctx:set(caster, component.MONSTER_TOXIC_RADIANCE, state)
end

register.system({
    id = "magic.monster_toxic_radiance.tick",
    scope = "active",
    query = { component.MONSTER_TOXIC_RADIANCE },
    before = { "monster.decision" },
    update = system.update,
})

return system
