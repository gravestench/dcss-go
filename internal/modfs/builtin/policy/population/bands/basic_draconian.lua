-- Source basic draconians share a two-to-five escort. A third of eligible
-- leaders bring it after absolute depth nineteen; member selection can
-- include classed draconians from absolute depth twenty-four onward.
local profile = {
    min = 2,
    max = 5,
    chance_denominator = 3,
    min_depth = 19,
    condition = "base_draconian",
    member_policy = "policy.population.bands.draconian",
    basic_draconian = true,
}

return profile
