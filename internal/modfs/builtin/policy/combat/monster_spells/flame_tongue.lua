-- Flame Tongue keeps its own zap profile while sharing the existing fire
-- beam contact rules with stronger fire spells and Vehumet's avatar.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local flame_tongue = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_FLAME_TONGUE)

-- Reject targets beyond this spell's short source range before casting.
function flame_tongue.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Resolve fire armour, resistance, and source credit through beam contact.
function flame_tongue.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return flame_tongue
