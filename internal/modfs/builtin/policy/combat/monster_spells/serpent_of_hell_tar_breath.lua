-- Tartarus fires draining, miasma, then corrosive force in source order.
local breath = require("policy.combat.monster_serpent_breath")
local spells = require("ids.spells")

local effect = {}
local spell_id = spells.SPELL_SERPENT_OF_HELL_TAR_BREATH

-- Use the composite spell's range and one safe source tracer.
function effect.plan(ctx, caster, foe)
    return breath.plan(ctx, caster, foe, spell_id)
end

-- Each head applies its own resistance and lingering cloud behavior.
function effect.resolve(ctx, caster, foe, slot, plan)
    return breath.resolve(ctx, caster, foe, slot, plan, spell_id)
end

return effect
