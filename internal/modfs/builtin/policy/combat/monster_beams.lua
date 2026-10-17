local resolution = require("policy.combat.monster_beams.resolution")
local targeting = require("policy.combat.monster_beams.targeting")

local beam = {}

beam.plan = targeting.plan
beam.resolve = resolution.resolve

return beam
