-- Call Down Damnation explodes at the selected cell using its own source
-- zap profile. The blast's resistance and HP changes stay with the shared
-- beam impact owner rather than this target-selection file.
-- Source: mon-cast.cc and zap-data.h:ZAP_CALL_DOWN_DAMNATION.
local beam = require("policy.combat.monster_beams")
local damage = require("policy.combat.monster_beams.damage")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local targeting = require("policy.combat.monster_area.targeting")
local spells = require("ids.spells")

local effect = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_CALL_DOWN_DAMNATION)
local FOE_RATIO = 80

-- Damnation immunity must remove a monster from the source tracer's
-- expected impact; an immune ally is harmless collateral as well.
local function expected_impact(ctx, victim)
    return damage.resisted(ctx, victim, 100, profile)
end

-- The foe's saved cell is the source of the radius-one explosion. Evaluate
-- its whole footprint rather than refusing every possible allied contact.
function effect.plan(ctx, caster, foe)
    return targeting.plan(ctx, caster, foe, profile,
        profile.explosion_radius, FOE_RATIO, expected_impact)
end

-- Reuse the named zap's three dice and damnation immunity at each cell.
-- A changed target direction is rejected by the shared beam resolver.
function effect.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return effect
