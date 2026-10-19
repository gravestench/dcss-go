local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Viper count depends on caster spell HD, so the intent selects
-- that actor before resolving the later count draw.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- Effective spell HD increases attempts by one per five HD.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 1 + roll.spell(ctx, math.floor(hd / 5) + 1)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_MANA_VIPER,
            monsters.MONS_MANA_VIPER, 2, nil)
    end
end

return effect
