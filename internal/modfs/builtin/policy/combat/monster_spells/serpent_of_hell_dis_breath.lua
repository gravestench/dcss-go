-- Dis fires metal splinters, quicksilver, then Lehudib's crystal spear.
local breath = require("policy.combat.monster_serpent_breath")
local spells = require("ids.spells")

local effect = {}
local spell_id = spells.SPELL_SERPENT_OF_HELL_DIS_BREATH

-- Use the composite spell's range and one safe source tracer.
function effect.plan(ctx, caster, foe)
    return breath.plan(ctx, caster, foe, spell_id)
end

-- Each head keeps its own armour, dispel, and crystal damage policy.
function effect.resolve(ctx, caster, foe, slot, plan)
    return breath.resolve(ctx, caster, foe, slot, plan, spell_id)
end

return effect
