-- Theory of operation: conduct supplies a nominal piety amount to this
-- owner. The source rule rounds it once, then handles each candidate point:
-- penance, gift timeout, upper taper, loss hysteresis, and finally gain.
-- Saved counters stay in religion.worship. Rank and gift checks are signals
-- for later god systems; this module never invents a substitute gift.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local jewellery_capabilities = require("constants.jewellery_capabilities")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local limits = require("constants.piety")
local modes = require("constants.god_piety_modes")
local signals = require("constants.religion_signals")
local streams = require("constants.rng_streams")

local piety = {}

-- Source div_rand_round consumes one draw only when the division leaves a
-- remainder. Keeping that gate prevents a new exact division from shifting
-- all later religion-stream outcomes.
local function random_round(ctx, numerator, denominator)
    local whole = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder == 0 then
        return whole
    end

    local draw = ctx:random(streams.RELIGION, denominator)

    return whole + (draw < remainder and 1 or 0)
end

-- Report the threshold for a human-facing one-through-six star rank.
-- Example: breakpoint(1) is 30, while breakpoint(6) is 160.
function piety.breakpoint(stars)
    local threshold = limits.BREAKPOINTS[stars]

    if not threshold then
        error("piety breakpoint requires one through six stars")
    end

    return threshold
end

-- Xom interprets the same stored number as a mood. Gozag has no ordinary
-- piety rank, so neither follows the six source star thresholds.
function piety.rank(god_id, points)
    if god_id == gods.NO_GOD then
        return 0
    end

    local definition = catalog.get(categories.GODS, god_id)

    if definition.piety_mode == modes.NONE then
        return 0
    end

    if definition.piety_mode == modes.XOM then
        for index, threshold in ipairs(limits.XOM_BREAKPOINTS) do
            if points <= threshold then
                return index
            end
        end

        return #limits.XOM_BREAKPOINTS + 1
    end

    for stars = #limits.BREAKPOINTS, 1, -1 do
        if points >= piety.breakpoint(stars) then
            return stars
        end
    end

    return 0
end

-- Signal both ranks after the saved number crosses a boundary. The later
-- ability and passive owners decide what that rank means for this god.
local function signal_rank(ctx, player, state, old_points)
    local old_rank = piety.rank(state.god_id, old_points)
    local new_rank = piety.rank(state.god_id, state.piety)

    if old_rank ~= new_rank then
        ctx:signal(signals.RANK_CHANGED, {
            player = player,
            god_id = state.god_id,
            old_rank = old_rank,
            new_rank = new_rank,
        })
    end
end

-- Source checks gifts after an accepted point or an upper taper. A future
-- gift system can subscribe without piety guessing any god's actual gift.
local function signal_gift(ctx, player, state)
    ctx:signal(signals.GIFT_CHECK, {
        player = player,
        god_id = state.god_id,
        piety = state.piety,
    })
end

-- Ru does not taper and stops at the sixth-star threshold. Other gods get
-- separate short-circuit one-in-three rolls at 160 and 100 piety.
local function tapered(ctx, state)
    if state.god_id == gods.RU then
        return state.piety >= limits.RU_MAX
    end

    if state.piety >= limits.MAX then
        return true
    end

    if state.piety >= piety.breakpoint(6) and
        ctx:random(streams.RELIGION, limits.UPPER_TAPER_CHANCE) == 0 then
        return true
    end

    return state.piety >= piety.breakpoint(4) and
        ctx:random(streams.RELIGION, limits.UPPER_TAPER_CHANCE) == 0
end

-- Pay debts before changing piety. Timeout normally spends three quarters
-- of remaining candidates; Elyvilon, Jiyva, and Nemelex are source exemptions.
local function gain_point(ctx, player, state)
    local god_id = state.god_id
    local penance = state.penance[god_id] or 0

    if penance > 0 then
        state.penance[god_id] = penance - 1

        return
    end

    if state.gift_timeout > 0 then
        state.gift_timeout = state.gift_timeout - 1

        if god_id ~= gods.JIYVA and
            god_id ~= gods.NEMELEX_XOBEH and
            god_id ~= gods.ELYVILON and
            ctx:random(streams.RELIGION, limits.TIMEOUT_CHANCE) ~= 0 then
            return
        end
    end

    if tapered(ctx, state) then
        if god_id ~= gods.RU then
            signal_gift(ctx, player, state)
        end

        return
    end

    local old_points = state.piety

    if state.piety_hysteresis > 0 then
        state.piety_hysteresis = state.piety_hysteresis - 1
    else
        state.piety = state.piety + 1
    end

    signal_rank(ctx, player, state, old_points)
    signal_gift(ctx, player, state)
end

-- Example: gain(ctx, player, 3, 2, false) may award one or two candidate
-- points, then resolves each candidate in source debt and taper order.
function piety.gain(ctx, player, numerator, denominator, scale)
    if type(numerator) ~= "number" or numerator % 1 ~= 0 or
        type(denominator) ~= "number" or denominator % 1 ~= 0 or
        denominator <= 0 then
        error("piety gain requires integer numerator and positive denominator")
    end

    if numerator <= 0 then
        return false
    end

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state then
        error("piety gain requires worship state")
    end

    if state.god_id == gods.NO_GOD then
        return false
    end

    local definition = catalog.get(categories.GODS, state.god_id)

    if definition.piety_mode ~= modes.ORDINARY then
        return false
    end

    local amount = numerator

    if scale and jewellery_effects.has(ctx, player,
        jewellery_capabilities.FAITH) then
        amount = amount + random_round(ctx, amount,
            limits.FAITH_DIVISOR)
    end

    local points = random_round(ctx, amount, denominator)
    local old_penance = state.penance[state.god_id] or 0
    local old_rank = piety.rank(state.god_id, state.piety)

    for _ = 1, points do
        gain_point(ctx, player, state)
    end

    if state.god_id ~= gods.IGNIS and
        state.piety > (state.piety_max[state.god_id] or 0) then
        state.piety_max[state.god_id] = state.piety
    end

    ctx:set(player, component.RELIGION_WORSHIP, state)

    -- Rank effects read the committed worship state. A god's Lua module
    -- decides whether a crossed threshold has a one-time consequence.
    local new_rank = piety.rank(state.god_id, state.piety)

    if new_rank > old_rank and definition.behavior_module then
        local handler = require(definition.behavior_module)

        if handler.rank_gained then
            handler.rank_gained(ctx, player, old_rank, new_rank)
        end
    end

    -- Some rank-minus-one passives stay active under penance but must
    -- retry actor effects when the final debt point is paid. The god's
    -- module owns that transition, not the common piety calculation.
    if old_penance > 0 and
        (state.penance[state.god_id] or 0) == 0 and
        definition.behavior_module then
        local handler = require(definition.behavior_module)

        if handler.penance_ended then
            handler.penance_ended(ctx, player)
        end
    end

    return true
end

-- Loss fills one point of hysteresis before reducing piety. Ignis records
-- the depleted reserve so leaving and rejoining cannot restore spent piety.
function piety.lose(ctx, player, points)
    if type(points) ~= "number" or points % 1 ~= 0 then
        error("piety loss requires integer points")
    end

    if points <= 0 then
        return false
    end

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state then
        error("piety loss requires worship state")
    end

    local old_points = state.piety
    local old_buffer = state.piety_hysteresis

    state.piety_hysteresis = math.min(limits.HYSTERESIS_LIMIT,
        old_buffer + points)

    local borrowed = state.piety_hysteresis - old_buffer

    state.piety = math.max(0, state.piety - (points - borrowed))

    if (state.penance[state.god_id] or 0) == 0 then
        signal_rank(ctx, player, state, old_points)
    end

    if state.god_id == gods.IGNIS then
        state.min_ignis_piety = state.piety
    end

    ctx:set(player, component.RELIGION_WORSHIP, state)

    return true
end

return piety
