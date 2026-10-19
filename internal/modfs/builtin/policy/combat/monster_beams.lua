-- Example: beam.plan(ctx, caster, foe, profile) with foe on another level -> nil plan before resolution.
local resolution = require("policy.combat.monster_beams.resolution")
local targeting = require("policy.combat.monster_beams.targeting")

local beam = {}

-- Monster beam spells share targeting and resolution while their catalog profiles supply projectile rules.
beam.plan = targeting.plan
beam.resolve = resolution.resolve

return beam
