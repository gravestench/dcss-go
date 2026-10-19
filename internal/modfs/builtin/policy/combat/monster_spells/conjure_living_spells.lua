-- The tome's shared spellbook creates a set of saved living spell actors.
-- Source: mon-cast.cc:SPELL_CONJURE_LIVING_SPELLS.
local living = require("policy.combat.monster_summons.living_spells")
local self_target = require("policy.combat.monster_support.self_target")

local effect = {}

-- Placement happens during resolution, so targeting stores only the caster.
function effect.plan(ctx, caster)
    if living.at_cap(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- Resolve the source species mapping before trying adjacent placements.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    living.spawn(ctx, caster)
end

return effect
