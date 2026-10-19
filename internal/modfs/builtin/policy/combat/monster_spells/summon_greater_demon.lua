local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local demons = require("policy.combat.monster_summons.demons")
local strength = require("policy.combat.monster_summons.strength")
local spells = require("ids.spells")

local effect = {}

-- Greater demon tier choice happens only after the cast is committed;
-- planning records the summoner that supplies its side.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- A greater demon uses the source tier split and slower HD duration scale.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local degree = math.min(2 + math.floor(hd / 10), 6)

    summons.spawn(ctx, caster, spells.SPELL_SUMMON_GREATER_DEMON,
        demons.greater(ctx), degree, nil)
end

return effect
