local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local demons = require("policy.combat.monster_summons.demons")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local spells = require("ids.spells")

local effect = {}

-- Common demon tier rolls occur for each attempted spawn, so the
-- plan only fixes the caster whose side they inherit.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- A fresh common demon tier and kind are drawn for every attempt.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 1 + roll.spell(ctx, math.floor(hd / 10) + 1)
    local degree = math.min(2 + math.floor(hd / 10), 6)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_DEMON,
            demons.common(ctx), degree, nil)
    end
end

return effect
