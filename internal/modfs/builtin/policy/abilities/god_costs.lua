-- Theory of operation: a divine ability owns its god and source cost
-- tuple. This shared owner reads live worship and Invocations, checks
-- penance, rolls failure once, and spends ordinary MP or piety only when
-- a successful timed action reaches its commitment point.
local component = require("constants.component")
local magic_power = require("policy.magic.power")
local piety = require("policy.religion.piety")
local roll = require("policy.combat.roll")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local silence = require("policy.world.silence")

local costs = {}

-- Patron changes and penance remove a power even if saved piety remains
-- above its unlock threshold. Mod gods use the same live check.
function costs.available(ctx, player, god_id, rank)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    return worship ~= nil and worship.god_id == god_id and
        (worship.penance[god_id] or 0) == 0 and
        not silence.actor(ctx, player) and
        piety.rank(god_id, worship.piety) >= rank
end

-- A free targeting prompt checks the current MP pool before producing
-- a timed intent. Resolution repeats this check when it spends MP.
function costs.enough_magic(ctx, player, amount)
    local magic = ctx:get(player, component.MAGIC)

    return magic ~= nil and magic.current >= amount
end

-- Source fail_basis::invo subtracts effective Invocations and the
-- integer piety fraction. The ability supplies its own source tuple.
function costs.failure_chance(ctx, player, base, scale, divisor)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local training = magic_power.training(ctx, player,
        skills.SK_INVOCATIONS, scale)

    return math.max(0, base - training -
        math.floor(worship.piety / divisor))
end

-- Source failure compares the average of three widened religion rolls
-- with the current chance, leaving the action committed on a failure.
function costs.failed(ctx, player, base, scale, divisor)
    local chance = costs.failure_chance(ctx, player, base, scale,
        divisor)
    local result = roll.average_three(ctx, streams.RELIGION, 100)

    return result < chance
end

-- An ordinary numeric ability piety cost is not fixed in DCSS:
-- generic_cost(base) adds one draw from zero through half the base.
function costs.piety_cost(ctx, base)
    if base <= 0 then
        return 0
    end

    local extra = math.floor((base + 1) / 2) + 1

    return base + ctx:random(streams.RELIGION, extra)
end

-- Spend once after the effect succeeds; the piety owner handles loss
-- hysteresis and emits rank changes if this crosses a breakpoint.
function costs.spend(ctx, player, mp, piety_points)
    if not costs.enough_magic(ctx, player, mp) then
        error("divine ability lacks MP at commitment")
    end

    local magic = ctx:get(player, component.MAGIC)

    magic.current = magic.current - mp
    ctx:set(player, component.MAGIC, magic)

    if piety_points > 0 then
        piety.lose(ctx, player, piety_points)
    end
end

return costs
