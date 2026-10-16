-- Source: item-use.cc:SCR_TORMENT and spl-goditem.cc:torment.
local catalog = require("policy.catalog")
local component = require("constants.component")
local item_ids = require("ids.items")
local damage = require("policy.magic.damage")
local monster_torment = require("policy.combat.torment")
local player_health = require("policy.combat.player_health")
local player_resistance = require("policy.combat.player_resistance")
local scrolls = require("policy.scrolls")

local effect = {}
local SIGHT_RADIUS = 7

function effect.prepare()
    return nil
end

function effect.apply(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local health = ctx:get(player, component.HEALTH)
    local loss = player_resistance.torment_loss(ctx, player,
        health.current)

    if loss > 0 then
        ctx:emit("read", "Your body is wracked with pain!")
        player_health.damage(ctx, player, loss)
    else
        ctx:emit("read", "You feel a surge of unholy energy.")
    end

    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if target ~= player then
            local position = ctx:get(target, component.POSITION)
            local victim = ctx:get(target, component.HEALTH)

            if victim.current > 0 and
                position.level_id == origin.level_id and
                ctx:visible(origin.level_id, origin.x, origin.y,
                    SIGHT_RADIUS, position.x, position.y) then
                local actor = ctx:get(target, component.ACTOR)
                local definition = catalog.get("monsters", actor.kind_id)
                local amount = monster_torment.monster_loss(definition,
                    victim.current)

                if amount > 0 then
                    damage.apply(ctx, target, amount)
                    ctx:emit("read", "The " .. definition.name ..
                        " convulses!")
                end
            end
        end
    end
end

scrolls.register(item_ids.SCR_TORMENT, effect)

return effect
