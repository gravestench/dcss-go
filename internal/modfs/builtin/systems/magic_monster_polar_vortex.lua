-- Monster storm enchantments advance before the caster chooses its action.
-- Player Polar Vortex has a separate post-cast tick in its spell module.
local channels = require("constants.message_channels")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local duration = require("policy.combat.monster_support.duration")
local senses = require("policy.character.senses")
local vortex = require("policy.magic.effects.zaps.polar_vortex")
local zap_ids = require("policy.magic.effects.zaps.ids")

local system = {}

-- A newly ended storm starts cooldown now; the older cooldown is aged
-- first, so this same action cannot consume the fresh cooldown's first tick.
local function cooldown(ctx, caster, delta)
    local state = ctx:get(caster, component.MONSTER_VORTEX_COOLDOWN)

    if not state then
        return
    end

    state.remaining_aut = state.remaining_aut - delta

    if state.remaining_aut > 0 then
        ctx:set(caster, component.MONSTER_VORTEX_COOLDOWN, state)
        return
    end

    ctx:remove(caster, component.MONSTER_VORTEX_COOLDOWN)

    if senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.DURATION,
            "The winds around the " .. display.name(ctx, caster) ..
                " calm down.")
    end
end

-- Theory of operation: only the acting monster advances its storm and
-- cooldown. The shared wind policy reads current terrain and occupancy;
-- when the last ring resolves, this owner saves a source-style cooldown.
function system.update(ctx, caster, delta)
    if ctx:has(caster, component.PLAYER) then
        return
    end

    cooldown(ctx, caster, delta)

    if not ctx:has(caster, zap_ids.component.POLAR_VORTEX) then
        return
    end

    local pulse_aut = duration.action_aut(ctx, caster)

    if not vortex.tick(ctx, caster, delta, pulse_aut) then
        return
    end

    ctx:add(caster, component.MONSTER_VORTEX_COOLDOWN, {
        remaining_aut = duration.vortex_cooldown(ctx, caster),
    })

    if senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.DURATION,
            "The winds around the " .. display.name(ctx, caster) ..
                " start to calm down.")
    end
end

register.system({
    id = "magic.monster_polar_vortex.tick",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = system.update,
})

return system
