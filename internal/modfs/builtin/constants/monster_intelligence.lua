-- Intelligence levels gate monster tactics and item use without a separate AI class.

-- Source: mon-enum.h:mon_intel_type.
local intelligence = {
    BRAINLESS = "I_BRAINLESS",
    ANIMAL = "I_ANIMAL",
    HUMAN = "I_HUMAN",
}

intelligence.rank = {
    [intelligence.BRAINLESS] = 0,
    [intelligence.ANIMAL] = 1,
    [intelligence.HUMAN] = 2,
}

return intelligence
