local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local electrical_bolt = {}
-- Electrical Bolt uses beam contact and its catalogued electric flavour for each traced hit.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_ELECTRICAL_BOLT)

-- Example: electrical_bolt.plan(ctx, caster, foe) with clear ray -> entity plan for an electric trace
-- Saves a foe-directed aim after checking the electric ray can reach an enemy safely.
function electrical_bolt.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Trace the electric ray anew, including any bounce, before applying contacts.
function electrical_bolt.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return electrical_bolt
