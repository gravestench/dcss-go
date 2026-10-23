-- Pentagram summons one demon from the source tier and a guaranteed kind
-- of second demonic creature. A hostile first demon stays player-owned for
-- duration and attribution, while its saved attitude drives normal AI.
local cards = require("ids.cards")
local demon_tiers = require("data.demon_tiers")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.cards.effects.summons")

local pentagram = {}

pentagram.uses_tier = true

local first_tiers = {
    [0] = 4,
    [1] = 3,
    [2] = 2,
}

local second_kinds = {
    [0] = monsters.MONS_HELL_HOUND,
    [1] = monsters.MONS_RAKSHASA,
    [2] = monsters.MONS_PANDEMONIUM_LORD,
}

-- The tier chooses both bodies. Source gives the primary demon a one in
-- tier-plus-four chance of disobedience and both summons degree five-tier.
function pentagram.apply(ctx, player, request)
    local tier = request.tier
    local demon_tier = first_tiers[tier]

    if not demon_tier then
        error("Pentagram requires a source power tier")
    end

    local kinds = demon_tiers[demon_tier]
    local first = kinds[ctx:random(streams.CARDS, #kinds) + 1]
    local hostile = ctx:random(streams.CARDS, tier + 4) == 0
    local degree = 5 - tier
    local created

    if hostile then
        created = summons.hostile(ctx, player, cards.SUMMON_DEMON,
            first, degree)
    else
        created = summons.friendly(ctx, player, cards.SUMMON_DEMON,
            first, degree)
    end

    if not created then
        ctx:emit("religion", "You see a puff of smoke.")
    end

    summons.friendly(ctx, player, cards.SUMMON_DEMON,
        second_kinds[tier], degree)
end

return pentagram
