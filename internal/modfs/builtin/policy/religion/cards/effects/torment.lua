-- The source card calls torment_player on a living character, so it never
-- touches nearby monsters. Undead and demonic characters instead receive
-- source Holy Word damage directly; neither route is an area effect.
local component = require("constants.component")
local holiness = require("policy.character.holiness")
local player_health = require("policy.combat.player_health")
local resistance = require("policy.combat.player_resistance")

local torment = {}

-- Source holy_word_player removes half of current HP minus one. The living
-- route uses the same nonlethal resistance formula as other self-Torment.
function torment.apply(ctx, player)
    local health = ctx:get(player, component.HEALTH)

    if not health then
        return
    end

    if holiness.undead_or_demonic(ctx, player) then
        local loss = math.max(0, math.floor(health.current / 2) - 1)

        if loss > 0 then
            ctx:emit("religion", "You are blasted by holy energy!")
            player_health.damage(ctx, player, loss, false, nil)
        end

        return
    end

    local loss = resistance.torment_loss(ctx, player, health.current)

    if loss > 0 then
        ctx:emit("religion", "You are tormented!")
        player_health.damage(ctx, player, loss, false, nil)
    end
end

return torment
