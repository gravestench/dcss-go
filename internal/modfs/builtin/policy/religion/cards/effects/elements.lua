-- Elements cycles through three of four elemental families. The source
-- tier picks each family's stronger member; the ordinary summon owner
-- handles position, friendly AI, expiry, and durable source identity.
local cards = require("ids.cards")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.cards.effects.summons")

local elements = {}

elements.uses_tier = true

local families = {
    {
        monsters.MONS_RAIJU,
        monsters.MONS_WIND_DRAKE,
        monsters.MONS_SHOCK_SERPENT,
    },
    {
        monsters.MONS_BASILISK,
        monsters.MONS_CATOBLEPAS,
        monsters.MONS_IRON_GOLEM,
    },
    {
        monsters.MONS_FIRE_VORTEX,
        monsters.MONS_MOLTEN_GARGOYLE,
        monsters.MONS_FIRE_DRAGON,
    },
    {
        monsters.MONS_ICE_BEAST,
        monsters.MONS_POLAR_BEAR,
        monsters.MONS_ICE_DRAGON,
    },
}

-- Pick a starting family uniformly, then take three consecutive families
-- with wraparound. This avoids three unrelated random category rolls.
function elements.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Elements requires a source power tier")
    end

    local start = ctx:random(streams.CARDS, #families) + 1

    for offset = 0, 2 do
        local family = families[(start + offset - 1) % #families + 1]

        summons.friendly(ctx, player, cards.ELEMENTS,
            family[tier + 1], tier + 2)
    end
end

return elements
