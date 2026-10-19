local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Geryon's fixed beast needs no foe cell; select its summoner so a
-- rewritten intent cannot move the beast to another owner.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- Geryon's fixed Hell Beast keeps source abjuration degree four.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    summons.spawn(ctx, caster, spells.SPELL_SUMMON_HELL_BEAST,
        monsters.MONS_HELL_BEAST, 4, nil)
end

return effect
