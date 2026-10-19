-- An orc leader's cry grants Might to eligible same-genus allies nearby.
local cries = require("policy.combat.monster_battlecries")
local spells = require("ids.spells")

local effect = {}

-- The group is worth inspiring only when one ally can newly gain Might.
function effect.plan(ctx, caster, foe)
    return cries.plan(ctx, caster, foe, spells.SPELL_BATTLECRY)
end

-- Resolve the planned self action through the shared cry owner, which
-- writes recipient boons and makes the audible battle announcement.
-- Example: an orc knight inspires one healthy orc warrior.
function effect.resolve(ctx, caster, _, _, plan)
    cries.resolve(ctx, caster, plan, spells.SPELL_BATTLECRY)
end

return effect
