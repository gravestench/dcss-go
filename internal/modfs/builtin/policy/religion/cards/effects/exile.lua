-- Exile repeatedly chooses a nearby monster with a one-slot chance of
-- choosing nobody. Every successful pick uses the ordinary Abyss owner,
-- which stores banishment origin and handles conduct and relocation.
local abyss = require("policy.world.abyss")
local branches = require("ids.branches")
local component = require("constants.component")
local nearby = require("policy.religion.cards.effects.nearby")
local streams = require("constants.rng_streams")

local exile = {}

exile.uses_tier = true

-- Source choose_random_nearby_monster starts its reservoir at weight one.
-- This leaves a chance that the first pick is empty even with monsters in
-- sight. After a banishment, the next pass sees only remaining actors.
local function choose(ctx, player)
    local chosen = nil
    local weight = 1

    for _, candidate in ipairs(nearby.monsters(ctx, player)) do
        weight = weight + 1

        if ctx:random(streams.CARDS, weight) == 0 then
            chosen = candidate
        end
    end

    return chosen
end

-- Tier zero makes one attempt. Higher tiers add their tier plus a bounded
-- random number of further attempts; an empty first pick stops the card.
function exile.apply(ctx, player, request)
    local position = ctx:get(player, component.POSITION)

    if ctx:level_branch(position.level_id) == branches.BRANCH_ABYSS then
        ctx:emit("religion", "Nothing happens.")

        return
    end

    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Exile requires a source power tier")
    end

    local attempts = 1 + tier + ctx:random(streams.CARDS, tier + 1)

    for index = 1, attempts do
        local candidate = choose(ctx, player)

        if not candidate then
            if index == 1 then
                ctx:emit("religion", "Nothing happens.")
            end

            break
        end

        abyss.banish_monster(ctx, candidate.entity,
            candidate.definition, player)
    end
end

return exile
