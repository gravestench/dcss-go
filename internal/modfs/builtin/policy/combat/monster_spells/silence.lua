-- Silence is a self enchantment whose field moves with its caster. The
-- shared world policy answers whether any later action occurs inside it.
-- Source: mon-cast.cc:SPELL_SILENCE and areas.cc:monster::silence_radius.
local channels = require("constants.message_channels")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local duration = require("policy.combat.monster_support.duration")
local self_target = require("policy.combat.monster_support.self_target")
local senses = require("policy.character.senses")

local effect = {}

-- An existing active aura makes another cast redundant. A caster still
-- needs its own saved handle for the ordinary monster intent boundary.
function effect.plan(ctx, caster, foe)
    local state = ctx:get(caster, component.MONSTER_SILENCE)

    if state and state.remaining_aut > 0 or
        not self_target.useful(ctx, caster, foe) then
        return nil
    end

    return self_target.plan(caster)
end

-- Protective enchantment duration uses the same speed-adjusted source
-- class as other monster auras. The field radius is derived afterward.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local state = {
        remaining_aut = duration.protection(ctx, caster),
    }

    if ctx:has(caster, component.MONSTER_SILENCE) then
        ctx:set(caster, component.MONSTER_SILENCE, state)
    else
        ctx:add(caster, component.MONSTER_SILENCE, state)
    end

    if senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.SPELL,
            "The " .. display.name(ctx, caster) ..
            "'s surroundings become eerily quiet.")
    end
end

return effect
