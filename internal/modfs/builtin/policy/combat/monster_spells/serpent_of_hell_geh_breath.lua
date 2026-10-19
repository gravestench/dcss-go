-- Gehenna's three heads breathe fire, burning cloud, then a fireball.
local breath = require("policy.combat.monster_serpent_breath")
local spells = require("ids.spells")

local effect = {}
local spell_id = spells.SPELL_SERPENT_OF_HELL_GEH_BREATH

-- Use the composite spell's range and one safe source tracer.
function effect.plan(ctx, caster, foe)
    return breath.plan(ctx, caster, foe, spell_id)
end

-- Fire the heads in source order as one committed monster action.
function effect.resolve(ctx, caster, foe, slot, plan)
    return breath.resolve(ctx, caster, foe, slot, plan, spell_id)
end

return effect
