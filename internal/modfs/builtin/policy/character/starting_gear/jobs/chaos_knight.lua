-- Example: A Chaos Knight's chosen weapon receives the chaotic brand at creation.
-- Source: ng-setup.cc; Chaos Knight's chosen weapon starts chaotic.
local brands = require("constants.weapon_brands")
local gear = require("policy.character.starting_gear")
local jobs = require("ids.jobs")

local rule = {}

-- Give the selected Chaos Knight weapon its chaos ego before equipment slot assignment.
function rule.prepare_weapon(chosen)
    chosen.ego = brands.CHAOS
end

gear.register(jobs.JOB_CHAOS_KNIGHT, rule)

return rule
