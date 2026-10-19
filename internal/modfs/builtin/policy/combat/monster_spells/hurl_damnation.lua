local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local hurl_damnation = {}
-- Hurl Damnation keeps its explosion and damnation flavour in the beam catalog profile.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_HURL_DAMNATION)

-- Example: hurl_damnation.plan(ctx, caster, foe) with reachable foe -> cell plan for a damnation blast
-- Targets the catalogued damnation explosion.
function hurl_damnation.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The blast uses its catalogued damnation flavour around the saved endpoint.
function hurl_damnation.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return hurl_damnation
