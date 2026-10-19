-- Hunting Call quickens same-genus allies' movement through saved Swift.
local cries = require("policy.combat.monster_battlecries")
local spells = require("ids.spells")

local effect = {}

-- Existing Haste or Swift makes an ally ineligible for another call.
function effect.plan(ctx, caster, foe)
    return cries.plan(ctx, caster, foe, spells.SPELL_HUNTING_CALL)
end

-- The source recipient rules and duration are shared with Battlecry;
-- the choice of Swift rather than Might remains this spell's identity.
-- Example: a pack caller quickens an unbuffed packmate.
function effect.resolve(ctx, caster, _, _, plan)
    cries.resolve(ctx, caster, plan, spells.SPELL_HUNTING_CALL)
end

return effect
