-- Test fixture: a mod may replace the entire choice policy.
register.choice_policy(function(_species, _job, _species_first)
    return "banned", false
end)
