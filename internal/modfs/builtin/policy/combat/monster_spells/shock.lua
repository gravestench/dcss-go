-- Shock uses the same reflecting electric beam for ordinary monsters and
-- Makhleb's temporary god caster. The registered profile owns all numbers.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local shock = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SHOCK)

-- Save the selected target, leaving the reflected trace to resolution.
function shock.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Trace contact through the shared electric resistance and damage owner.
function shock.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return shock
