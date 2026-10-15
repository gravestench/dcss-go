local catalog = require("policy.catalog")
local death = require("policy.death")
local draining = require("policy.combat.brands.draining")
local net = require("policy.combat.net")

register.system({
    id = "actor.death",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "character.training" },
    update = function(ctx)
        local kills = {}

        for _, entity in ipairs(ctx:signals("player_kill")) do
            kills[ctx:id(entity)] = true
        end

        for _, entity in ipairs(ctx:query({ "core.health" })) do
            local health = ctx:get(entity, "core.health")

            if health.current <= 0 then
                if entity == ctx:player() then
                    ctx:emit("death", "You die.")
                else
                    local actor = ctx:get(entity, "core.actor")
                    local position = ctx:get(entity, "core.position")

                    if not actor or not position then
                        error("dead monster " .. ctx:id(entity) .. " has no actor or position")
                    end

                    local definition = catalog.get("monsters", actor.kind_id)

                    if kills[ctx:id(entity)] then
                        local xp = death.experience(definition, health.max)
                        local player = ctx:player()
                        local progress = ctx:get(player, "core.progression")
                        local training = ctx:get(player, "core.skill_training")

                        if not progress or not training or progress.total_xp < 0 then
                            error("invalid Dungeon experience state")
                        end

                        progress.total_xp = progress.total_xp + xp
                        training.available_xp = training.available_xp + 10 * xp
                        ctx:set(player, "core.progression", progress)
                        ctx:set(player, "core.skill_training", training)
                        draining.recover(ctx, player, xp)
                        death.corpse(ctx, definition, position)
                    end

                    net.release(ctx, entity)
                    death.drop_inventory(ctx, entity, position)
                    ctx:remove_actor(entity, position.level_id)
                    ctx:destroy(entity)
                    ctx:emit("death", "The " .. definition.name .. " dies.")
                end
            end
        end
    end,
})
