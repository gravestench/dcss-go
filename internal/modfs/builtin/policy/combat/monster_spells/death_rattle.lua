-- Death Rattle uses the ordinary penetrating beam for immediate damage,
-- then the world-cloud owner for each crossed cell. Clouds carry their own
-- attribution and save state; this spell does not keep a parallel trail.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local clouds = require("ids.clouds")
local spells = require("ids.spells")
local trail = require("policy.combat.monster_beams.trail")

local death_rattle = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_DEATH_RATTLE)
local FOE_RATIO = 30

-- A reachable enemy gives the caster a ray; the shared beam planner guards
-- against excessive friendly fire using the source's 30% foe threshold.
function death_rattle.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile, {
        foe_ratio = FOE_RATIO,
    })
end

-- Source beam.cc rolls four to seven turns independently for each cell.
function death_rattle.after_endpoint(ctx, caster, _, _, endpoint)
    trail.place(ctx, caster, clouds.CLOUD_MIASMA, endpoint, 4, 4)
end

-- Contact damage resolves before the lingering miasma trail is placed.
function death_rattle.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, death_rattle)
end

return death_rattle
