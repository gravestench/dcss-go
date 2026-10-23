-- Theory of operation: Nemelex's piety checks deal counts into three
-- player-owned decks. The cards themselves are sampled only when drawn,
-- so gift RNG never depends on which effects a mod has registered.
local channels = require("constants.message_channels")
local decks = require("ids.decks")
local draws = require("policy.religion.gifts.draws")
local gifts = require("policy.religion.gifts")
local gods = require("constants.gods")
local limits = require("constants.piety")
local piety = require("policy.religion.piety")
local state = require("policy.religion.cards.state")
local streams = require("constants.rng_streams")

local nemelex = {}

local maxima = {
    [decks.ESCAPE] = 13,
    [decks.DESTRUCTION] = 26,
    [decks.SUMMONING] = 13,
}

local deck_order = {
    decks.ESCAPE,
    decks.DESTRUCTION,
    decks.SUMMONING,
}

local deck_names = {
    [decks.ESCAPE] = "escape",
    [decks.DESTRUCTION] = "destruction",
    [decks.SUMMONING] = "summoning",
}

-- Source x_chance_in_y avoids an RNG draw when the chance is certain.
-- First gifts get an extra early chance; later gifts use only the second.
local function chance(ctx, numerator, denominator)
    if numerator <= 0 then
        return false
    end

    if numerator >= denominator then
        return true
    end

    return ctx:random(streams.RELIGION, denominator) < numerator
end

-- A first gift may arrive just above one star. Failure falls through to
-- the ordinary one-in-three chance, matching the source's draw order.
local function due(ctx, worship)
    local first_star = piety.breakpoint(1)

    if worship.piety < first_star then
        return false
    end

    local surplus = worship.piety - first_star + 1
    local previous = worship.gift_total[gods.NEMELEX_XOBEH] or 0

    if previous == 0 and chance(ctx, surplus, piety.breakpoint(2)) then
        return true
    end

    return ctx:random(streams.RELIGION, 3) == 0 and
        chance(ctx, surplus, limits.MAX)
end

-- Each gift slot picks independently at source 3:1:1 weights. A chosen
-- full deck wastes that slot instead of rerouting it to another deck.
local function chosen_deck(ctx)
    local drawn = ctx:random(streams.RELIGION, 5)

    if drawn < 3 then
        return decks.DESTRUCTION
    end

    if drawn == 3 then
        return decks.SUMMONING
    end

    return decks.ESCAPE
end

-- Source random_range(4, 13) attempts every slot even if all decks fill.
-- Only the count changes here; no card identity exists until a draw action.
local function deal(ctx, owned)
    local attempts = 4 + ctx:random(streams.RELIGION, 10)
    local changed = false

    for _ = 1, attempts do
        local deck_id = chosen_deck(ctx)
        local count = owned.counts[deck_id] or 0

        if count < maxima[deck_id] then
            owned.counts[deck_id] = count + 1
            changed = true
        end
    end

    return changed
end

-- Examples use current live counts, not a cached string, so the notice
-- accurately reflects both successful gifts and deck caps.
local function summary(owned)
    local parts = {}

    for _, deck_id in ipairs(deck_order) do
        local count = owned.counts[deck_id] or 0

        if count > 0 then
            parts[#parts + 1] = count .. " " .. deck_names[deck_id] ..
                (count == 1 and " card" or " cards")
        end
    end

    if #parts <= 1 then
        return parts[1] or ""
    end

    local last = table.remove(parts)

    return table.concat(parts, ", ") .. " and " .. last
end

-- A successful chance spends a gift and timeout even when every chosen
-- deck was full. This is why the counter sits outside the `changed` case.
function nemelex.check(ctx, player, worship)
    if not due(ctx, worship) then
        return false
    end

    local owned = state.get(ctx, player)
    local changed = deal(ctx, owned)

    if changed then
        state.set(ctx, player, owned)
        ctx:emit(channels.RELIGION,
            "Nemelex Xobeh deals you some cards!")
        ctx:emit(channels.RELIGION,
            "You now have " .. summary(owned) .. ".")
    else
        ctx:emit(channels.RELIGION,
            "Nemelex Xobeh goes to deal, but finds you have enough cards.")
    end

    gifts.record(ctx, player, 5 + draws.average(ctx, 9))

    return true
end

-- Renouncing Nemelex destroys all owned decks and the ordered stack,
-- while `religion.worship` retains the lifetime gift count.
function nemelex.leave(ctx, player)
    state.clear(ctx, player)
end

return nemelex
