-- Velocity shortens the player's Slow and changes nearby monster speed.
-- Existing status owners save and expire the resulting enchantments.
local boons = require("policy.combat.monster_support.boons")
local component = require("constants.component")
local duration = require("policy.combat.monster_support.duration")
local eligibility = require("policy.combat.monster_support.boon_eligibility")
local nearby = require("policy.religion.cards.effects.nearby")
local slow = require("policy.combat.monster_slow")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local velocity = {}

velocity.uses_tier = true

-- Source x_chance_in_y does not draw for impossible or certain outcomes.
-- Keeping those branches explicit preserves the card stream at tiers 0 and 2.
local function chance(ctx, numerator, denominator)
    if numerator <= 0 then
        return false
    end

    if numerator >= denominator then
        return true
    end

    return ctx:random(streams.CARDS, denominator) < numerator
end

-- Source mons_invuln_will excludes only the catalog's absolute 5000 Will.
-- A normal resisted Slow spell does not govern this card's direct enchant.
local function vulnerable(candidate)
    return candidate.definition.willpower ~= 5000
end

-- The source scans each visible body once, choosing hostile Slow or allied
-- Haste in that order. A successful chance counts even if stasis blocks Slow.
function velocity.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Velocity requires a source power tier")
    end

    local changed = false
    local player_slow = ctx:get(player, component.PLAYER_SLOW)

    if player_slow and player_slow.remaining_aut > 0 and
        chance(ctx, tier, 2) then
        player_slow.remaining_aut = 1
        ctx:set(player, component.PLAYER_SLOW, player_slow)
        changed = true
    end

    for _, candidate in ipairs(nearby.monsters(ctx, player)) do
        if vulnerable(candidate) then
            if targets.enemy(ctx, player, candidate.entity) then
                if chance(ctx, 1 + tier, 3) then
                    slow.apply(ctx, candidate.entity,
                        candidate.definition, nil, streams.CARDS)
                    changed = true
                end
            elseif targets.real_allied(ctx, candidate.entity) and
                eligibility.haste(ctx, candidate.entity) and
                chance(ctx, tier, 2) then
                boons.haste(ctx, candidate.entity,
                    duration.beneficial(ctx, candidate.entity,
                        streams.CARDS))
                ctx:emit("religion", "The " ..
                    candidate.definition.name .. " seems to speed up.")
                changed = true
            end
        end
    end

    if not changed then
        ctx:emit("religion", "Nothing happens.")
    end
end

return velocity
