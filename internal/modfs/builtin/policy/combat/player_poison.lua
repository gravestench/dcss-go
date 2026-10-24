-- Ordinary poison exposure shares one resistance gate whether the source
-- is a poisoned missile or a venom weapon. Curare performs its own source
-- resistance check before writing poison, so it uses the raw status owner.
local brands = require("policy.combat.brands")
local resistance = require("policy.combat.player_resistance")
local streams = require("constants.rng_streams")

local poison = {}

-- Source player.cc rejects immunity, usually resists one positive pip,
-- and doubles exposure under poison vulnerability before saving duration.
function poison.deliver(ctx, amount, source_id)
    local level = resistance.poison(ctx, ctx:player())

    if level >= 3 or level > 0 and
        ctx:random(streams.MELEE, 3) ~= 0 then
        return false
    end

    if level < 0 then
        amount = amount * 2
    end

    brands.poison(ctx, amount, source_id)

    return true
end

return poison
