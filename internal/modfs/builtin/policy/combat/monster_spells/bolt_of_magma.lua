local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local bolt_of_magma = {}
-- Magma follows the beam trace while its mixed fire/physical flavour comes from the catalog profile.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_BOLT_OF_MAGMA)

-- Example: bolt_of_magma.plan(ctx, caster, foe) with in-range foe -> entity plan for mixed-flavour resolution
-- Uses the catalog's mixed magma flavour along one ray.
function bolt_of_magma.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The catalog's mixed flavour is applied at each beam contact traced at resolution.
function bolt_of_magma.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return bolt_of_magma
