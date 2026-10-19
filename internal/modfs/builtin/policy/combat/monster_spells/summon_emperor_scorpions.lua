local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- The emperor variant uses the caster's effective spell HD, so
-- planning fixes its owner before drawing a count.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The emperor variant keeps the same count scale but stronger degree five.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 1 + roll.spell(ctx, math.floor(hd / 5) + 1)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_EMPEROR_SCORPIONS,
            monsters.MONS_EMPEROR_SCORPION, 5, nil)
    end
end

return effect
