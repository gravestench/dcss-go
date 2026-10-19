-- Test fixture: a mod may replace the entire choice policy.
-- Example: this policy bans even Human/Fighter during character selection.
local choice = {}

-- Reject every pair to verify a replacement policy can ban choices that the
-- built-in rules would normally allow.
function choice.allowed(_species, _job)
    return false
end

-- Pair the banned rating with the fixture's false result, exercising the
-- same return contract that the character menu reads from production policy.
register.choice_policy(function(species, job, _species_first)
    return "banned", choice.allowed(species, job)
end)

return choice
