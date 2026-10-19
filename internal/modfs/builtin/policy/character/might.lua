-- Example: Drinking Might refreshes its duration with a power-dependent random spread.
local component = require("constants.component")

local might = {}

-- Source: potion.cc:PotionMight. Power sets the added duration spread;
-- callers choose the saved RNG stream that owns their effect.
-- Might extends an existing duration up to the source cap instead of replacing it with a fresh roll.
function might.apply(ctx, player, power, stream)
    local durations = ctx:get(player, component.DURATIONS)

    if not durations then
        error("Might requires player durations")
    end

    local previous = durations.might_aut
    local added = 35 + ctx:random(stream, power)

    durations.might_aut = math.min(800, previous + added * 10)
    ctx:set(player, component.DURATIONS, durations)

    if previous > 0 then
        return "You feel mightier all of a sudden."
    end

    return "You feel very mighty all of a sudden."
end

return might
