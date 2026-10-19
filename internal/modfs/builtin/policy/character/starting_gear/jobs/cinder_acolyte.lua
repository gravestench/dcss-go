-- Example: A Cinder Acolyte's chosen weapon is flaming and cursed at creation.
-- Source: ng-setup.cc; Cinder Acolyte starts with a cursed flaming weapon.
local brands = require("constants.weapon_brands")
local gear = require("policy.character.starting_gear")
local jobs = require("ids.jobs")

local rule = {}

-- Flaming and curse state are applied to the chosen weapon as a starting grant.
function rule.prepare_weapon(chosen)
    chosen.plus = -1
    chosen.ego = brands.FLAMING
end

gear.register(jobs.JOB_CINDER_ACOLYTE, rule)

return rule
