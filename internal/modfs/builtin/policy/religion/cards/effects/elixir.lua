-- Elixir grants rapid HP and MP recovery for a source tier-dependent
-- duration. The player status system owns later healing and timer expiry.
local component = require("constants.component")
local streams = require("constants.rng_streams")

local elixir = {}

elixir.uses_tier = true

-- Source sets, rather than adds to, its duration. Duration is stored in
-- aut so a nonstandard action speed heals for its actual elapsed delay.
function elixir.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Elixir requires a source power tier")
    end

    local turns = 1 + 3 * tier + ctx:random(streams.CARDS, 3)
    local status = {
        remaining_aut = turns * 10,
    }

    if ctx:has(player, component.RELIGION_CARD_ELIXIR) then
        ctx:set(player, component.RELIGION_CARD_ELIXIR, status)
    else
        ctx:add(player, component.RELIGION_CARD_ELIXIR, status)
    end

    ctx:emit("religion", "You begin rapidly regenerating health and magic.")
end

return elixir
