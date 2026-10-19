local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- The Sentinel is anchored to its summoner; targeting an enemy
-- would make its arrival follow a changing foe cell.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The source _summon path creates one Hell Sentinel at degree two.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    summons.spawn(ctx, caster, spells.SPELL_SUMMON_HELL_SENTINEL,
        monsters.MONS_HELL_SENTINEL, 2, nil)
end

return effect
