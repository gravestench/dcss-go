-- Interesting outside events raise Xom's saved gift timeout, which doubles
-- as his attention span. Xom's own acts do not stimulate him again.
local capabilities = require("constants.jewellery_capabilities")
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local jewellery = require("policy.inventory.jewellery_effects")
local kinds = require("constants.xom_stimulation")
local limits = require("constants.piety")
local streams = require("constants.rng_streams")

local stimulation = {}

local speech = {
    [kinds.NORMAL] = {
        "Xom is interested.",
        "Xom is mildly amused.",
        "Xom is amused.",
        "Xom is highly amused!",
        "Xom thinks this is hilarious!",
        "Xom roars with laughter!",
    },

    [kinds.INTRIGUED] = {
        "Xom is interested.",
        "Xom is very interested.",
        "Xom is extremely interested.",
        "Xom is intrigued!",
        "Xom is very intrigued!",
        "Xom is fascinated!",
    },
}

local thresholds = {
    20,
    40,
    60,
    80,
    160,
}

-- Source piety_scale adds one Faith quarter by stochastic rounding. This
-- happens before the interestingness draw, so Faith changes its bound.
local function scaled(ctx, player, amount, stream)
    if not jewellery.has(ctx, player, capabilities.FAITH) then
        return amount
    end

    local quarter = math.floor(amount / limits.FAITH_DIVISOR)
    local remainder = amount % limits.FAITH_DIVISOR

    if remainder > 0 and
        ctx:random(stream, limits.FAITH_DIVISOR) < remainder then
        quarter = quarter + 1
    end

    return amount + quarter
end

-- The six phrases use source thresholds, with the highest phrase reserved
-- for an interestingness roll above 160.
local function phrase(kind, value)
    local messages = speech[kind]

    if not messages then
        error("unknown Xom stimulation kind " .. tostring(kind))
    end

    local band = 1

    for _, threshold in ipairs(thresholds) do
        if value > threshold then
            band = band + 1
        end
    end

    return messages[band]
end

-- An event is interesting only when its roll exceeds current interest and
-- reaches ten. Forced speech reports the result without altering that rule.
function stimulation.apply(ctx, player, amount, kind, options)
    options = options or {}

    if type(amount) ~= "number" or amount % 1 ~= 0 then
        error("Xom stimulation requires integer interestingness")
    end

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state or state.god_id ~= gods.XOM or amount <= 0 or
        options.self_caused then
        return false
    end

    local stream = options.stream or streams.RELIGION
    local result = math.min(limits.MAX,
        ctx:random(stream, scaled(ctx, player, amount, stream)))
    local interested = result >= 10 and result > state.gift_timeout

    if interested then
        state.gift_timeout = result
        ctx:set(player, component.RELIGION_WORSHIP, state)
    end

    if interested or options.force_message then
        ctx:emit(channels.RELIGION,
            phrase(kind or kinds.NORMAL, result))
    end

    return interested
end

return stimulation
