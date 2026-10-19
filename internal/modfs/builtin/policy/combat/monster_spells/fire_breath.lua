-- Fire Breath uses the shared penetrating-ray owner; its source-specific
-- damage dice, fire resistance, and natural power live in its beam profile.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local fire_breath = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_FIRE_BREATH)

-- Plan a foe-directed ray before the natural breath action is committed.
function fire_breath.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Apply contact damage to each actor along the fire ray in trace order.
function fire_breath.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return fire_breath
