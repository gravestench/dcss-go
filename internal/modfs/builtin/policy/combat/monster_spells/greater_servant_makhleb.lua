local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local choice = require("policy.combat.monster_summons.choice")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Makhleb's five greater servants have equal source probability.
local kinds = {
    monsters.MONS_EXECUTIONER,
    monsters.MONS_GREEN_DEATH,
    monsters.MONS_BLIZZARD_DEMON,
    monsters.MONS_BALRUG,
    monsters.MONS_CACODEMON,
}

-- Makhleb's servant is chosen after commitment, while this plan
-- fixes the monster whose side the servant joins.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The invocation chooses one servant rather than using demon tier rolls.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    summons.spawn(ctx, caster, spells.SPELL_GREATER_SERVANT_MAKHLEB,
        choice.uniform(ctx, kinds), 5, nil)
end

return effect
