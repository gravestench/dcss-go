local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local poison = require("policy.combat.monster_beams.poison")
local spells = require("ids.spells")

local venom_bolt = {}
-- Venom Bolt traces a penetrating poison projectile; contact owns resistance and poison.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_VENOM_BOLT)

-- Example: venom_bolt.plan(ctx, caster, foe) with two foes on one ray
-- -> entity plan; resolution later traces both contacts
-- The penetrating profile lets the planned aim reach a foe behind another enemy.
function venom_bolt.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The penetrating ray applies poison and resistance at each contact traced at resolution.
function venom_bolt.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, poison)
end

return venom_bolt
