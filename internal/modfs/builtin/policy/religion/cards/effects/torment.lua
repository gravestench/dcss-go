-- Torment turns its own body into the target for undead and demonic
-- characters. A living character instead unleashes ordinary Torment in a
-- seven-cell radius, sharing all resistance and damage rules with scrolls.
local area = require("policy.combat.torment_area")
local component = require("constants.component")
local holiness = require("policy.character.holiness")
local player_health = require("policy.combat.player_health")

local torment = {}

-- Source holy_word_player removes half of current HP minus one, while
-- ordinary Torment affects every susceptible actor in LOS_NO_TRANS.
function torment.apply(ctx, player)
    if holiness.undead_or_demonic(ctx, player) then
        local health = ctx:get(player, component.HEALTH)
        local loss = math.max(0, math.floor(health.current / 2) - 1)

        if loss > 0 then
            ctx:emit("religion", "You are blasted by holy energy!")
            player_health.damage(ctx, player, loss, false, nil)
        end

        return
    end

    area.apply(ctx, player, "religion")
end

return torment
