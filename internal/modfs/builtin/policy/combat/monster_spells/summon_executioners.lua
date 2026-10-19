local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Executioner count and duration share caster spell HD; planning
-- keeps the owner fixed until both source formulas run.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- Count scales at five HD; duration scales more slowly at ten HD.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 1 + roll.spell(ctx, math.floor(hd / 5) + 1)
    local degree = math.min(2 + math.floor(hd / 10), 6)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_EXECUTIONERS,
            monsters.MONS_EXECUTIONER, degree, nil)
    end
end

return effect
