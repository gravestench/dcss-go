-- Theory of operation: Lugonu first forces an uncontrolled player
-- blink, then warps nearby hostile monsters around the new position.
-- The player blink overrides magical stasis as in source Crawl;
-- monsters still obey their own no-teleport and habitat rules.
local abilities = require("ids.abilities")
local attitudes = require("constants.attitude")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local landing = require("policy.combat.monster_displacement.landing")
local registry = require("policy.abilities.registry")
local relocate = require("policy.combat.monster_displacement.relocate")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local unsafe_move = require("policy.character.unsafe_move")

local bend = {}

-- The two-star power is suspended by penance and patron changes.
function bend.available(ctx, player)
    return costs.available(ctx, player, gods.LUGONU, 2)
end

-- Source enough_hp requires more HP than the fixed two-point payment.
function bend.prepare(ctx, player, input)
    if not costs.enough_magic(ctx, player, 1) then
        return "You do not have enough magic."
    end

    local health = ctx:get(player, component.HEALTH)

    if not health or health.current <= 2 then
        return "You do not have enough health."
    end

    local warning = unsafe_move.warning(ctx, player)

    if warning and not input.forced then
        return { confirmation = warning }
    end

    return nil
end

-- Try nonadjacent landing cells first, then adjacent cells if the source
-- random search cannot find one. A blocked blink still spends the power.
local function blink_player(ctx, player)
    local x, y = landing.ordinary(ctx, player)

    if not x then
        x, y = landing.ordinary(ctx, player, true)
    end

    if not x or not relocate.move(ctx, player, x, y,
        player, true, true) then
        ctx:emit("religion", "You feel jittery for a moment.")

        return
    end

    unsafe_move.break_ice(ctx, player)
end

-- Each adjacent hostile body gets one independent coin flip after the
-- player has moved; friendly and teleport-immune bodies are untouched.
local function warp_nearby(ctx, player)
    local origin = ctx:get(player, component.POSITION)

    for _, monster in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
    })) do
        if monster ~= player then
            local position = ctx:get(monster, component.POSITION)
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if position.level_id == origin.level_id and
                distance <= 1 and
                targets.attitude(ctx, monster) == attitudes.HOSTILE and
                relocate.can_move(ctx, monster) and
                ctx:random(streams.RELIGION, 2) == 0 then
                local x, y = landing.ordinary(ctx, monster)

                if x then
                    relocate.move(ctx, monster, x, y, player)
                end
            end
        end
    end
end

-- A failed invocation spends time only. Successful effects precede the
-- source's MP and HP cost, which cannot reduce the player below one HP.
function bend.resolve(ctx, player)
    if costs.failed(ctx, player, 40, 5, 20) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    ctx:emit("religion", "Space bends violently around you!")
    blink_player(ctx, player)
    warp_nearby(ctx, player)
    costs.spend(ctx, player, 1, 0)

    local health = ctx:get(player, component.HEALTH)

    health.current = health.current - 2
    ctx:set(player, component.HEALTH, health)
end

registry.add(abilities.LUGONU_BEND_SPACE, {
    name = "Bend Space",
    available = bend.available,
    confirmation_needed = function(ctx, player)
        return unsafe_move.warning(ctx, player) ~= nil
    end,
    confirmation_message = unsafe_move.warning,
    prepare = bend.prepare,
    resolve = bend.resolve,
})

return bend
