-- Swarm creates source-duration killer bees through the common summon
-- owner. Every bee retains the card as its source and the player's friendly
-- allegiance, so expiry and AI do not need card-specific exceptions.
local cards = require("ids.cards")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.cards.effects.summons")

local swarm = {}

swarm.uses_tier = true

-- Source selects one through three, six, or nine bees by tier. Each bee
-- independently looks for an adjacent legal cell and lasts degree three.
function swarm.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier < 0 or tier > 2 then
        error("Swarm requires a source power tier")
    end

    local count = 1 + ctx:random(streams.CARDS, (tier + 1) * 3)

    for _ = 1, count do
        summons.friendly(ctx, player, cards.SUMMON_BEE,
            monsters.MONS_KILLER_BEE, 3)
    end
end

return swarm
