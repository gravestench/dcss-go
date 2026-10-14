-- Test fixture: a policy cannot invent missing start mechanics.
register.choice_policy(function(_species, _job, _species_first)
    return "recommended", true
end)
