-- Example: A small Gladiator receives throwing gear sized for its body.
-- Source: ng-setup.cc; throwing ammunition follows species body size.
local gear = require("policy.character.starting_gear")
local items = require("ids.items")
local jobs = require("ids.jobs")
local size = require("constants.size")

local rule = {}

-- Body size selects the Gladiator throwing stack after the weapon choice has been settled.
function rule.extra(species)
    local ammo
    local quantity

    if size.rank[species.size] >= size.rank[size.LARGE] then
        ammo = items.MI_LARGE_ROCK
        quantity = 1
    elseif size.rank[species.size] <= size.rank[size.SMALL] then
        ammo = items.MI_BOOMERANG
        quantity = 2
    else
        ammo = items.MI_JAVELIN
        quantity = 1
    end

    return {
        {
            kind_id = ammo,
            quantity = quantity,
        },
    }
end

gear.register(jobs.JOB_GLADIATOR, rule)

return rule
