local component = require("constants.component")
local resistance = require("policy.combat.player_resistance")

local petrification = {}

-- Source: player.cc:player::petrify. A second hit completes the first stage
-- on the next status tick; a fully petrified player cannot be petrified again.
function petrification.apply(ctx, player)
    if resistance.petrification(ctx, player) then
        return false
    end

    local current = ctx:get(player, component.PLAYER_PETRIFICATION)

    if current and current.petrified_aut > 0 then
        return false
    end

    if current and current.petrifying_aut > 0 then
        current.petrifying_aut = 1
        ctx:set(player, component.PLAYER_PETRIFICATION, current)
        ctx:emit("status", "Your limbs have turned to stone.")

        return true
    end

    ctx:add(player, component.PLAYER_PETRIFICATION, {
        petrifying_aut = 30,
        petrified_aut = 0,
    })
    ctx:emit("status", "You are slowing down.")

    return true
end

-- Source: player-reacts.cc:_decrement_petrification and
-- player.cc:player::fully_petrify. The current action's elapsed aut advances
-- the first stage; full petrification lasts six to nine turns.
function petrification.tick(ctx, player, elapsed)
    local current = ctx:get(player, component.PLAYER_PETRIFICATION)

    if not current then
        return
    end

    if current.petrified_aut > 0 then
        current.petrified_aut = math.max(0,
            current.petrified_aut - elapsed)

        if current.petrified_aut == 0 then
            ctx:remove(player, component.PLAYER_PETRIFICATION)
            ctx:emit("duration", "You turn to flesh and can move again.")
        else
            ctx:set(player, component.PLAYER_PETRIFICATION, current)
        end

        return
    end

    local previous = current.petrifying_aut

    current.petrifying_aut = math.max(0, previous - elapsed)

    if current.petrifying_aut == 0 then
        current.petrified_aut = 60 + ctx:random("petrification", 40)
        ctx:emit("duration", "You have turned to stone.")
    elseif previous >= 15 and current.petrifying_aut < 15 then
        ctx:emit("duration", "Your limbs are stiffening.")
    end

    ctx:set(player, component.PLAYER_PETRIFICATION, current)
end

-- Source: ouch.cc:ouch. These multipliers apply after armour and resistance
-- have produced ordinary damage, before the player's final HP loss.
function petrification.reduce_damage(ctx, player, amount)
    local current = ctx:get(player, component.PLAYER_PETRIFICATION)

    if not current then
        return amount
    end

    if current.petrified_aut > 0 then
        return math.floor(amount / 2)
    end

    if current.petrifying_aut > 0 then
        return math.floor(amount * 10 / 15)
    end

    return amount
end

return petrification
