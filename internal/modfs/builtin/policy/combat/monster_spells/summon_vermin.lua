local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local vermin = require("policy.combat.monster_summons.vermin")
local spells = require("ids.spells")

local effect = {}

-- Vermin count and kinds are cast-time draws; targeting an enemy
-- would incorrectly shift their source position.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The source adds a third vermin only on a one-in-four count draw.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = roll.spell(ctx, 4) == 0 and 3 or 2
    local degree = math.min(2 + math.floor(hd / 5), 6)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_VERMIN,
            vermin.pick(ctx), degree, nil)
    end
end

return effect
