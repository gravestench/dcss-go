-- A mod may replace the bundled name owner by path. This fixture keeps
-- the same public interface while making each mode visibly different.
local modes = require("constants.name_modes")

local names = {}

-- The test cares that callers import the effective file, not the seed.
function names.from_seed(_, _, mode)
    if mode == modes.SCROLL then
        return "MODDED LABEL"
    end

    if mode == modes.JIYVA then
        return "Jovial"
    end

    return "New Name"
end

-- A replacement may still draw a caller seed before returning its name.
function names.generate(ctx, stream, mode)
    local seed = ctx:random(stream, 4294967296)

    return names.from_seed(ctx, seed, mode)
end

return names
