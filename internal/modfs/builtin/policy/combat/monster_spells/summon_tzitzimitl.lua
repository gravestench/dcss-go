local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- The single Tzitzimitl appears by its summoner, so its intent
-- selects that actor rather than the current enemy.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The source _summon path creates one Tzitzimitl at degree two.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    summons.spawn(ctx, caster, spells.SPELL_SUMMON_TZITZIMITL,
        monsters.MONS_TZITZIMITL, 2, nil)
end

return effect
