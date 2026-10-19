local delay = require("policy.combat.delay")
local projectiles = require("policy.combat.player_projectiles")
local statuses = require("policy.magic.effects.statuses.player")
local movement = require("policy.character.movement")
local forms = require("policy.magic.effects.forms.player")
local rage = require("policy.character.rage")
local channel = require("policy.magic.channel")
local component = require("constants.component")
local intent = require("constants.intent")
local time = require("constants.time")
local abilities = require("ids.abilities")
local phases = require("constants.equipment_phases")

local timing = {}

local SLOWED_AUT_PER_TURN = 15
local HASTE_NUMERATOR = 2
local HASTE_DENOMINATOR = 3

-- Action cost is computed after command preparation so rejected no-time commands never consume energy.
-- Example: timing.player_speed(ctx, player) feeds the next accepted command's aut cost.
function timing.player_speed(ctx, player)
    local duration = ctx:get(player, component.DURATIONS)

    if not duration then
        error("player has no duration state for action timing")
    end

    local petrification = ctx:get(player,
        component.PLAYER_PETRIFICATION)

    if petrification and petrification.petrified_aut > 0 then
        return time.AUT_PER_TURN
    end

    local time_taken = statuses.slow_active(ctx, player) and
        SLOWED_AUT_PER_TURN or time.AUT_PER_TURN

    if petrification and petrification.petrifying_aut > 0 then
        time_taken = math.floor(time_taken * 15 / 10)
    end

    if duration.haste_aut == 0 and not rage.active(ctx, player) then
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

-- Speed and action kind meet here before the scheduler charges the player.
function timing.action_cost(ctx, player, input, time_taken)
    local equipment_delay = ctx:get(player, component.EQUIPMENT_DELAY)

    if equipment_delay and equipment_delay.phase == phases.RING_SWAP then
        return math.floor(time_taken / 2)
    end

    if input.intent_kind == intent.PLAYER_ABILITY and
        input.ability_id == abilities.ROLLING_CHARGE then
        local movement_delay = movement.scale(ctx,
            movement.base(ctx, player), time_taken)

        return math.max(time_taken, movement_delay,
            delay.player(ctx, time_taken))
    end

    if input.attack_target then
        return delay.player(ctx, time_taken)
    end

    if input.intent_kind == intent.MOVE then
        local base = movement.base(ctx, player)
        local swift = statuses.move_delay(ctx, player, base, false)

        return movement.scale(ctx, swift, time_taken)
    end

    if input.intent_kind == intent.RANGED then
        projectiles.practice(ctx, input.item_id)

        return delay.projectile(ctx, time_taken, input.item_id)
    end

    if input.intent_kind == intent.WIELD or
        input.intent_kind == intent.JEWELLERY_ON or
        input.intent_kind == intent.JEWELLERY_OFF then
        if input.item_id == 0 then
            return math.floor(time_taken * 3 / 10)
        end

        return math.floor(time_taken / 2)
    end

    return time_taken
end

-- The command bridge asks for this cost only after preparation produced a time-taking intent.
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
