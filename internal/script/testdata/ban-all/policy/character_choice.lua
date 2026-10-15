-- Test fixture: a mod may replace the entire choice policy.
local choice = {}

function choice.allowed(_species, _job)
    return false
end

register.choice_policy(function(species, job, _species_first)
    return "banned", choice.allowed(species, job)
end)

return choice
