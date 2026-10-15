-- Test fixture: a mod may override the built-in species/job restriction.
local choice = {}

function choice.allowed(_species, _job)
    return true
end

register.choice_policy(function(species, job, _species_first)
    return "recommended", choice.allowed(species, job)
end)

return choice
