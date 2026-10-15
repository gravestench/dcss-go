local delay = require("policy.combat.delay")
local projectiles = require("policy.combat.player_projectiles")
local statuses = require("policy.magic.effects.statuses.player")
local forms = require("policy.magic.effects.forms.player")
local channel = require("policy.magic.channel")
local component = require("constants.component")
local intent = require("constants.intent")
local time = require("constants.time")

local timing = {}

local SLOWED_AUT_PER_TURN = 15
local HASTE_NUMERATOR = 2
local HASTE_DENOMINATOR = 3
local LIQUEFACTION_MOVE_PENALTY = 3

function timing.player_speed(ctx, player)
    local duration = ctx:get(player, component.DURATIONS)

    if not duration then
        error("player has no duration state for action timing")
    end

    local time_taken = statuses.slow_active(ctx, player) and
        SLOWED_AUT_PER_TURN or time.AUT_PER_TURN

    if duration.haste_aut == 0 then
        return time_taken
    end

    local numerator = time_taken * HASTE_NUMERATOR
    time_taken = math.floor(numerator / HASTE_DENOMINATOR)

    if ctx:random("speed", HASTE_DENOMINATOR) <
        numerator % HASTE_DENOMINATOR then
        time_taken = time_taken + 1
    end

    return time_taken
end

function timing.action_cost(ctx, player, input, time_taken)
    if input.attack_target then
        return delay.player(ctx, time_taken)
    end

    if input.intent_kind == intent.MOVE then
        local cost = statuses.move_delay(ctx, player, time_taken, false)
        local aura = ctx:get(player, component.LIQUEFACTION)

        if aura and aura.remaining_aut > 0 then
            cost = cost + LIQUEFACTION_MOVE_PENALTY
        end

        return cost
    end

    if input.intent_kind == intent.RANGED then
        projectiles.practice(ctx, input.item_id)

        return delay.projectile(ctx, time_taken, input.item_id)
    end

    if input.intent_kind == intent.WIELD then
        if input.item_id == 0 then
            return math.floor(time_taken * 3 / 10)
        end

        return math.floor(time_taken / 2)
    end

    return time_taken
end

function timing.run(ctx, input)
    local player = ctx:player()
    local speed = timing.player_speed(ctx, player)
    local cost = timing.action_cost(ctx, player, input, speed)

    cost = forms.action_delay(ctx, player, cost)

    if input.intent_kind == intent.CHANNEL_WAIT then
        cost = channel.cost(ctx, player, cost)
    end

    return {
        cost = cost,
    }
end

register.policy({
    id = "command.timing",
    run = timing.run,
})

return timing
