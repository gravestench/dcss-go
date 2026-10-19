local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Every ufetubus belongs to this caster, so the plan preserves that
-- owner while the two-or-three count waits until resolution.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The source always attempts at least two ufetubi.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 2 + roll.spell(ctx, 2)
    local degree = math.min(2 + math.floor(hd / 5), 6)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_UFETUBUS,
            monsters.MONS_UFETUBUS, degree, nil)
    end
end

return effect
