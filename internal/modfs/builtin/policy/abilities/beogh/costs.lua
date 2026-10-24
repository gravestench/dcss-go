-- Theory of operation: Beogh's four actions share worship and resource
-- gates, but each supplies its own source rank and cost. The registry
-- asks availability without mutating ECS; only a committed timed action
-- rolls failure and spends MP or piety.
local component = require("constants.component")
local gods = require("constants.gods")
local magic_power = require("policy.magic.power")
local piety = require("policy.religion.piety")
local roll = require("policy.combat.roll")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")

local costs = {}

-- Penance suspends powers even when the saved piety number remains above
-- their unlock threshold; a new patron cannot use a stale Beogh menu row.
function costs.available(ctx, player, rank)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    return worship ~= nil and worship.god_id == gods.BEOGH and
        (worship.penance[gods.BEOGH] or 0) == 0 and
        piety.rank(gods.BEOGH, worship.piety) >= rank
end

-- All four actions draw MP from the live player component. Checking before
-- an aim or selection prompt lets cancellation stay free.
function costs.enough_magic(ctx, player, amount)
    local magic = ctx:get(player, component.MAGIC)

    return magic ~= nil and magic.current >= amount
end

-- Source fail_basis::invo subtracts effective Invocations times a per-power
-- multiplier and integer piety divided by that power's divisor.
function costs.failure_chance(ctx, player, base, scale, divisor)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local training = magic_power.training(ctx, player,
        skills.SK_INVOCATIONS, scale)

    return math.max(0, base - training -
        math.floor(worship.piety / divisor))
end

-- Ability failure compares the average of three source rolls with the
-- chance. Widened follow-up bounds avoid a biased integer average.
function costs.failed(ctx, player, base, scale, divisor)
    local chance = costs.failure_chance(ctx, player, base, scale,
        divisor)
    local result = roll.average_three(ctx, streams.RELIGION, 100)

    return result < chance
end

-- Piety uses the existing hysteresis owner while MP is deducted once.
-- Call this only after a valid action reaches its commitment boundary.
function costs.spend(ctx, player, mp, piety_points)
    if not costs.enough_magic(ctx, player, mp) then
        error("Beogh ability lacks MP at commitment")
    end

    local magic = ctx:get(player, component.MAGIC)

    magic.current = magic.current - mp
    ctx:set(player, component.MAGIC, magic)

    if piety_points > 0 then
        piety.lose(ctx, player, piety_points)
    end
end

return costs
