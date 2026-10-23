-- Hepliaklqana's source piety grows through exploration, independently of
-- ancestor abilities. Reusing the source numerator preserves the very
-- occasional one-point award rather than a guaranteed gain per cell.
local kinds = require("constants.religion_conduct")

-- Return the source's fourteen-unit offer while preserving pulse severity.
local function explore(_, _, _, _, denominator)
    return 14, denominator
end

local hepliaklqana = {
    likes = {
        [kinds.EXPLORATION] = {
            description = "you explore the world",
            bonus = 0,
            denom_bonus = 0,
            xl_denom = 0,
            special = explore,
        },
    },
}

return hepliaklqana
