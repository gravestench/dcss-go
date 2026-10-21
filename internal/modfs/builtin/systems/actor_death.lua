local catalog = require("policy.catalog")
local death = require("policy.death")
local death_hooks = require("policy.combat.death_hooks")
require("policy.combat.monster_bound_souls")
require("policy.combat.monster_flames.inferno")
require("policy.combat.monster_death_explosions.bennu")
require("policy.combat.monster_death_explosions.constructs")
require("policy.combat.monster_death_explosions.horror")
require("policy.combat.monster_death_explosions.husk")
require("policy.combat.monster_death_clouds")
require("policy.combat.monster_tactical.pikel")
require("policy.combat.unique_revival.boris")
require("policy.combat.unique_revival.natasha")
require("policy.combat.monster_death.slime_pit")
require("policy.combat.monster_death.pan_pigsty")
local draining = require("policy.combat.brands.draining")
local net = require("policy.combat.net")
local statuses = require("policy.magic.effects.statuses.player")
local stat_loss = require("policy.character.stat_loss")
local temporary_mutations = require("policy.mutations.temporary")
local evolution = require("policy.mutations.evolution")
local kill_effects = require("policy.combat.player_kill_effects")
local flay = require("policy.combat.monster_flay")
local component = require("constants.component")
local doom_howl = require("policy.combat.monster_doom_howl.ids")
local zap_ids = require("policy.magic.effects.zaps.ids")

local system = {}

-- Ordinary bands survive their leader. Remove entity references before
-- the leader is deleted so AI and saves never point at a dead actor.
local function release_band_links(ctx, leader)
    for _, entity in ipairs(ctx:query({ component.FOLLOWER })) do
        local follower = ctx:get(entity, component.FOLLOWER)

        if entity == leader or follower.leader == leader then
            ctx:remove(entity, component.FOLLOWER)
        end
    end
end

-- A Haunt target may die after summon expiry ran earlier in this action.
-- Clear saved victim handles before deleting the actor so restore never
-- receives a reference to an entity that the death phase destroyed.
local function clear_haunting(ctx, victim)
    for _, summon in ipairs(ctx:query({ component.SUMMON_HAUNTING })) do
        local state = ctx:get(summon, component.SUMMON_HAUNTING)

        if state.target == victim then
            ctx:remove(summon, component.SUMMON_HAUNTING)
        end
    end
end

-- An orb can outlive a monster it was homing toward. Keep the saved
-- trajectory but drop the dead entity handle before that actor is removed.
local function clear_orb_targets(ctx, victim)
    for _, orb in ipairs(ctx:query({ zap_ids.component.IOOD })) do
        local state = ctx:get(orb, zap_ids.component.IOOD)

        if state.target == victim then
            state.target = nil
            ctx:set(orb, zap_ids.component.IOOD, state)
        end
    end
end

-- Theory of operation: Award the player-kill signal before deleting defeated actors.
-- This keeps XP accounting tied to the actor that died.
-- Clones and Doom arrivals can grant XP without occupying an initial roster
-- slot. Record only credited XP so restore can bound progression correctly.
local function record_extra_reward(ctx, player, monster, marker, reward_id, xp)
    if not ctx:has(monster, marker) then
        return
    end

    local rewards = ctx:get(player, reward_id) or {
        earned_xp = 0,
    }

    rewards.earned_xp = rewards.earned_xp + xp

    if ctx:has(player, reward_id) then
        ctx:set(player, reward_id, rewards)
    else
        ctx:add(player, reward_id, rewards)
    end
end

-- Consume the player_kill signal before the next phase.

-- Death waits for constriction damage, then records kill rewards and drops before destroying the actor.
function system.update(ctx)
    local kills = {}

    for _, entity in ipairs(ctx:signals("player_kill")) do
        kills[ctx:id(entity)] = true
    end

    for _, entity in ipairs(ctx:query({ "core.health" })) do
        local health = ctx:get(entity, "core.health")

        if health and health.current <= 0 then
            if entity == ctx:player() then
                ctx:emit("death", "You die.")
            else
                local actor = ctx:get(entity, "core.actor")
                local position = ctx:get(entity, "core.position")

                if not actor or not position then
                    error("dead monster " .. ctx:id(entity) .. " has no actor or position")
                end

                local definition = catalog.get("monsters", actor.kind_id)

                local summoned = ctx:has(entity, component.SUMMON)

                -- Only a credited, nonsummoned kill grants player XP and advances XP-driven recovery clocks.
                if kills[ctx:id(entity)] and not summoned and
                    not ctx:has(entity, component.PIKEL_BAND) then
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
                    record_extra_reward(ctx, player, entity,
                        component.CHAOS_CLONE,
                        component.CHAOS_CLONE_REWARDS, xp)
                    record_extra_reward(ctx, player, entity,
                        doom_howl.ARRIVAL, doom_howl.REWARDS, xp)

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

                -- Release trapping links before inventory drops and corpse hooks inspect the dying actor.
                flay.release_for_ghost(ctx, entity)
                net.release(ctx, entity)
                local dropped = death.drop_inventory(ctx, entity, position)
                release_band_links(ctx, entity)
                ctx:remove_actor(entity, position.level_id)
                local consumed_corpse = death_hooks.run(ctx, entity,
                    definition, position,
                    kills[ctx:id(entity)] == true, dropped)

                -- Death hooks may consume the body; ordinary corpse placement runs only afterward.
                if kills[ctx:id(entity)] and not consumed_corpse and
                    not summoned and
                    not ctx:has(entity, component.PIKEL_BAND) then
                    local corpse = death.corpse(ctx, definition, position,
                        ctx:get(entity, component.VAULT_ORIGIN))
                    local arrival = ctx:get(entity, doom_howl.ARRIVAL)

                    if corpse and arrival then
                        ctx:add(corpse, doom_howl.ARRIVAL, {
                            created_aut = arrival.created_aut,
                        })
                    end
                end

                clear_haunting(ctx, entity)
                clear_orb_targets(ctx, entity)
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
