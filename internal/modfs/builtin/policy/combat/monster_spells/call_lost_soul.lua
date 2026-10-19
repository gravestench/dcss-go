local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- A Lost Soul inherits the summoner's side and position; its plan
-- records the summoner without depending on the current foe.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- A Lost Soul is a single degree-two creature belonging to its caster.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    summons.spawn(ctx, caster, spells.SPELL_CALL_LOST_SOUL,
        monsters.MONS_LOST_SOUL, 2, nil)
end

return effect
