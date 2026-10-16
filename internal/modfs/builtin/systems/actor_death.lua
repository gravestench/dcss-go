local catalog = require("policy.catalog")
local death = require("policy.death")
local death_hooks = require("policy.combat.death_hooks")
local draining = require("policy.combat.brands.draining")
local net = require("policy.combat.net")
local statuses = require("policy.magic.effects.statuses.player")
local stat_loss = require("policy.character.stat_loss")
local temporary_mutations = require("policy.mutations.temporary")
local evolution = require("policy.mutations.evolution")
local kill_effects = require("policy.combat.player_kill_effects")
local component = require("constants.component")

local system = {}

local function record_clone_reward(ctx, player, monster, xp)
    if not ctx:has(monster, component.CHAOS_CLONE) then
        return
    end

    local rewards = ctx:get(player, component.CHAOS_CLONE_REWARDS) or {
        earned_xp = 0,
    }

    rewards.earned_xp = rewards.earned_xp + xp

    if ctx:has(player, component.CHAOS_CLONE_REWARDS) then
        ctx:set(player, component.CHAOS_CLONE_REWARDS, rewards)
    else
        ctx:add(player, component.CHAOS_CLONE_REWARDS, rewards)
    end
end

function system.update(ctx)
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
                    local player_pos = ctx:get(player, "core.position")
                    local progress = ctx:get(player, "core.progression")
                    local training = ctx:get(player, "core.skill_training")

                    if not progress or not training or progress.total_xp < 0 then
                        error("invalid Dungeon experience state")
                    end

                    progress.total_xp = progress.total_xp + xp
                    training.available_xp = training.available_xp + 10 * xp
                    ctx:set(player, "core.progression", progress)
                    ctx:set(player, "core.skill_training", training)
                    record_clone_reward(ctx, player, entity, xp)

                    temporary_mutations.gain_experience(ctx, player, xp)
                    evolution.gain_experience(ctx, player, xp)
                    stat_loss.gain_experience(ctx, player, xp, training.cost_level)
                    draining.recover(ctx, player, xp)
                    kill_effects.run(ctx, player, definition, xp)
                    local adjacent = player_pos.level_id == position.level_id and
                        math.abs(player_pos.x - position.x) <= 1 and
                        math.abs(player_pos.y - position.y) <= 1

                    statuses.wereblood_kill(ctx, player, xp > 0,
                        adjacent, false)
                end

                net.release(ctx, entity)
                death.drop_inventory(ctx, entity, position)
                ctx:remove_actor(entity, position.level_id)
                local consumed_corpse = death_hooks.run(ctx, entity,
                    definition, position,
                    kills[ctx:id(entity)] == true)

                if kills[ctx:id(entity)] and not consumed_corpse then
                    death.corpse(ctx, definition, position,
                        ctx:get(entity, component.VAULT_ORIGIN))
                end

                ctx:destroy(entity)
                ctx:emit("death", "The " .. definition.name .. " dies.")
            end
        end
    end
end

register.system({
    id = "actor.death",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "character.training" },
    update = system.update,
})

return system
