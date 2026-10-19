local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Fire elemental count uses caster spell HD, while the plan
-- prevents a later intent from changing that caster.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- Fire elementals use the same count threshold but their own source ID.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 1 + (hd > 15 and 1 or 0) +
        roll.spell(ctx, math.floor(hd / 7) + 1)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_FIRE_ELEMENTALS,
            monsters.MONS_FIRE_ELEMENTAL, 3, nil)
    end
end

return effect
