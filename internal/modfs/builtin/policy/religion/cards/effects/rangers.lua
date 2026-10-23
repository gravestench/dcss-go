-- Rangers chooses source-tier ranged allies. It delegates all entity state
-- and placement to the shared card summon owner, keeping this file about
-- the card's composition and random count alone.
local cards = require("ids.cards")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.cards.effects.summons")

local rangers = {}

rangers.uses_tier = true

-- A single coinflip adds one base archer. The stronger placed archer is
-- always summoned, with degree decreasing from five to three by tier.
function rangers.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Rangers requires a source power tier")
    end

    local base = tier == 2 and
        monsters.MONS_NAGA_SHARPSHOOTER or
        monsters.MONS_CENTAUR_WARRIOR
    local placed = base

    if tier == 1 then
        placed = monsters.MONS_NAGA_SHARPSHOOTER
    elseif tier == 2 then
        placed = monsters.MONS_DEEP_ELF_MASTER_ARCHER
    end

    local extra = ctx:random(streams.CARDS, 2) == 0 and 1 or 0

    for _ = 1, 1 + extra do
        summons.friendly(ctx, player, cards.RANGERS,
            base, 5 - tier)
    end

    summons.friendly(ctx, player, cards.RANGERS,
        placed, 5 - tier)
end

return rangers
