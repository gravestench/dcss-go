-- Source mons_demon_tier classifies the catalog base glyph, not a subset
-- of demon species used by summoning tables. Antaeus is the one C exception.
local tiers = {
    [string.byte("&")] = -1,
    [string.byte("1")] = 1,
    [string.byte("2")] = 2,
    [string.byte("3")] = 3,
    [string.byte("4")] = 4,
    [string.byte("5")] = 5,
}

return tiers
