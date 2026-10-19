local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")
local stun = require("policy.combat.monster_beams.stun")

local stunning_burst = {}
-- Stunning Burst can pass through targets; beam contact applies its stun flavour at each hit.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_STUNNING_BURST)

-- Example: stunning_burst.plan(ctx, caster, foe) with two foes on one ray
-- -> entity plan; resolution later traces both contacts
-- The piercing profile lets the planned aim reach a foe behind another enemy.
function stunning_burst.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The piercing trace can stun more than one defender through contact.
function stunning_burst.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, stun)
end

return stunning_burst
