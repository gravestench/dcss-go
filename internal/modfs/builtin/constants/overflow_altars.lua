-- Source overflow scheduling and map selection share these depth and tag
-- names. A mod may add a matching DES map without changing scheduler code.
local overflow = {
    MIN_DEPTH = 3,
    MAX_DEPTH = 10,
    COUNT_TAG = "temple_overflow_",
    GENERIC_TAG = "temple_overflow_generic_",
    GENERIC_SUFFIX = "generic_",
}

return overflow
