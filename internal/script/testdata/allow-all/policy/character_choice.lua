-- Test fixture: a mod may override the built-in species/job restriction.
-- Example: this policy marks an otherwise banned species/job pair recommended.
local choice = {}

-- Permit every pair regardless of catalog recommendation, proving a mod can
-- replace the built-in species/job restriction completely.
function choice.allowed(_species, _job)
    return true
end

-- Report the allowed fixture result in the choice API's rating-plus-boolean
-- shape so character creation can consume it unchanged.
register.choice_policy(function(species, job, _species_first)
    return "recommended", choice.allowed(species, job)
end)

return choice
