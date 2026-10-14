local delay = require("policy.combat.delay")
local projectiles = require("policy.combat.player_projectiles")

register.policy({
    id = "command.timing",
    run = function(ctx, input)
        local duration = ctx:get(ctx:player(), "core.durations")

        if not duration then
            error("player has no duration state for action timing")
        end

        local time_taken = 10

        if duration.haste_aut > 0 then
            local numerator = 20
            time_taken = math.floor(numerator / 3)

            if ctx:random("speed", 3) < numerator % 3 then
                time_taken = time_taken + 1
            end
        end

        local cost = time_taken

        if input.attack_target then
            cost = delay.player(ctx, time_taken)
        elseif input.intent_kind == 13 then
            projectiles.practice(ctx, input.item_id)
            cost = delay.projectile(ctx, time_taken, input.item_id)
        elseif input.intent_kind == 11 then
            cost = input.item_id == 0 and math.floor(time_taken * 3 / 10) or
                math.floor(time_taken / 2)
        end

        return { cost = cost }
    end,
})
