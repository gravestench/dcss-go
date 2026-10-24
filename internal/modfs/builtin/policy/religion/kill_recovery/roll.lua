-- C++ random2(0) returns zero without consuming a draw. Rat kills still
-- grant the base Makhleb or Vehumet amount after passing the piety gate.
local streams = require("constants.rng_streams")

local roll = {}

-- Share the source zero-bound rule across individual god formulas.
function roll.random(ctx, bound)
    if bound <= 0 then
        return 0
    end

    return ctx:random(streams.RELIGION, bound)
end

return roll
