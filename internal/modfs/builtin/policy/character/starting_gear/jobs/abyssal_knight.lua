-- Source: ng-setup.cc; Abyssal Knight starts with an enchanted chosen weapon.
local gear = require("policy.character.starting_gear")
local jobs = require("ids.jobs")

local rule = {}

function rule.prepare_weapon(chosen)
    chosen.plus = 1
end

gear.register(jobs.JOB_ABYSSAL_KNIGHT, rule)

return rule
