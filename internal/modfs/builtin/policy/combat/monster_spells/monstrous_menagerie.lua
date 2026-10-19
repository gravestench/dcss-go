local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local choice = require("policy.combat.monster_summons.choice")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- A failed high-power Sphinx coinflip falls through to the ordinary pair.
local ordinary = {
    monsters.MONS_MANTICORE,
    monsters.MONS_LINDWURM,
}

-- The Sphinx power gate must not draw before commitment, so the
-- intent carries only the caster that supplies the power.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- Power gates the Sphinx draw; the ordinary pair gets its own draw.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local power = strength.power(ctx, caster,
        spells.SPELL_MONSTROUS_MENAGERIE)
    local kind

    if roll.spell(ctx, power) > 60 and roll.spell(ctx, 2) == 0 then
        kind = monsters.MONS_SPHINX
    else
        kind = choice.uniform(ctx, ordinary)
    end

    summons.spawn(ctx, caster, spells.SPELL_MONSTROUS_MENAGERIE,
        kind, 4, nil)
end

return effect
