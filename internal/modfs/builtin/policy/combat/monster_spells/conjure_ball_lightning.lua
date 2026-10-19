-- Monster Conjure Ball Lightning creates the same saved construct actors as
-- the player spell. The owner controls allegiance, power, and later blast
-- attribution; no parallel explosion implementation is needed.
-- Source: mon-cast.cc:SPELL_CONJURE_BALL_LIGHTNING.
local lightning = require("policy.magic.effects.summons.ball_lightning")
local self_target = require("policy.combat.monster_support.self_target")
local spells = require("ids.spells")
local strength = require("policy.combat.monster_summons.strength")

local effect = {}

-- The source chooses three nearby ball cells when the cast resolves, so the
-- plan records only the caster and spends no placement RNG.
function effect.plan(_, caster)
    return self_target.plan(caster)
end

-- Effective spell HD accounts for live magic modifiers before the source
-- power-to-ball-HD reduction occurs in the shared conjuration policy.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local power = strength.power(ctx, caster,
        spells.SPELL_CONJURE_BALL_LIGHTNING)

    lightning.spawn(ctx, caster, power)
end

return effect
