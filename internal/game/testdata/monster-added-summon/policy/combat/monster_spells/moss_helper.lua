local channels = require("constants.message_channels")
local monsters = require("ids.monsters")
local self_target = require("policy.combat.monster_support.self_target")
local spells = require("ids.spells")
local summons = require("policy.magic.effects.summons.common")

local effect = {}

-- This helper comes to the summoner rather than a foe, so plan the caster
-- without consuming random numbers before the book commits its spell.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The new spell reuses the production Akara summon owner and leaves the
-- mod-specific message in this effect file, where a modder can edit it.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local creature = summons.spawn(ctx, caster,
        spells.SPELL_MOSS_HELPER, monsters.MONS_RAT, 2, nil)

    if creature then
        ctx:emit(channels.SPELL, "A modded rat answers the call.")
    end
end

return effect
