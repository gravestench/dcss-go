-- Theory of operation: leaving a monster's reach may let it strike before
-- the player changes cells. Eligibility reads the monster's saved energy,
-- current statuses, target, and species facts. The strike uses ordinary
-- melee reactions; only its movement context and energy refund differ.
local adjacent = require("constants.adjacent_cells")
local behaviors = require("constants.ai_behaviors")
local boons = require("policy.combat.monster_support.boons")
local catalog = require("policy.catalog")
local component = require("constants.component")
local confusion = require("policy.magic.effects.statuses.confusing_touch")
local energy = require("policy.monster_energy")
local flags = require("constants.monster_flags")
local intent = require("constants.intent")
local melee = require("policy.combat.melee_actions")
local monsters = require("ids.monsters")
local profile = require("policy.combat.monster_profile")
local statuses = require("policy.magic.effects.statuses.player")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local invisibility = require("policy.potions.invisibility")

local opportunity = {}

local self_destructing = {
    [monsters.MONS_BALLISTOMYCETE_SPORE] = true,
    [monsters.MONS_BALL_LIGHTNING] = true,
    [monsters.MONS_LURKING_HORROR] = true,
    [monsters.MONS_FULMINANT_PRISM] = true,
    [monsters.MONS_BLOATED_HUSK] = true,
    [monsters.MONS_CREEPING_INFERNO] = true,
    [monsters.MONS_FOXFIRE] = true,
}

-- Sleeping, frightened, and physically disabled actors cannot react to a
-- departure. These checks happen before the chance roll in source Crawl.
local function unable_to_react(ctx, monster)
    local ai = ctx:get(monster, component.AI)
    local paralysis = ctx:get(monster, component.PARALYSIS)
    local stasis = ctx:get(monster, component.MONSTER_STASIS)

    return confusion.active(ctx, monster) or
        statuses.fear_active(ctx, monster) or
        ai and ai.behavior == behaviors.SLEEP or
        paralysis and paralysis.remaining_aut > 0 or
        stasis and (stasis.hibernating or stasis.petrified_aut > 0) or
        ctx:has(monster, component.HELD)
end

-- Source checks class and action state before spending its one-in-three
-- chance. A monster that could not follow the departing player gets no roll.
local function can_act(ctx, monster, definition)
    local health = ctx:get(monster, component.HEALTH)
    local attack = definition.attacks and definition.attacks[1]

    if not health or health.current <= 0 or
        not attack or attack.type_id == "AT_NONE" or
        targets.allied(ctx, monster) or
        unable_to_react(ctx, monster) or
        self_destructing[definition.id] then
        return false
    end

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.STATIONARY or flag == flags.PROJECTILE then
            return false
        end
    end

    local grip = ctx:get(monster, component.PLAYER_CONSTRICTION)

    return not grip or grip.by == ctx:player()
end

-- Source may_have_action_energy uses the largest possible energy gain,
-- while outpaced_by_player compares speed with the monster's movement cost.
-- Neither check consumes a random draw or advances the monster scheduler.
local function can_follow(ctx, monster, definition, elapsed_aut)
    local stored = ctx:get(monster, component.MONSTER_ENERGY)
    local actor = ctx:get(monster, component.ACTOR)

    if not stored or not actor then
        return false
    end

    local speed = statuses.frenzy_speed(ctx, monster, actor.speed)

    speed = boons.speed(ctx, monster, speed)

    if speed <= 0 or
        stored.points + math.ceil(speed * elapsed_aut / 10) <
            energy.threshold then
        return false
    end

    local move_cost = energy.cost(ctx, {
        actor = ctx:id(monster),
        kind_id = definition.id,
        intent = intent.MOVE,
    })

    return speed * elapsed_aut >= move_cost * 10
end

-- An actor adjacent to both cells keeps contact throughout the move.
local function adjacent_to(position, x, y)
    return math.max(math.abs(position.x - x),
        math.abs(position.y - y)) == 1
end

-- Keep this predicate public so a mod can inspect the exact movement gate
-- without duplicating the source energy and status rules.
function opportunity.eligible(ctx, monster, origin, destination, elapsed_aut)
    local position = ctx:get(monster, component.POSITION)
    local actor = ctx:get(monster, component.ACTOR)

    if not position or not actor or
        position.level_id ~= origin.level_id or
        not adjacent_to(position, origin.x, origin.y) or
        adjacent_to(position, destination.x, destination.y) then
        return false
    end

    local definition = profile.definition(ctx, monster,
        catalog.get("monsters", actor.kind_id))

    if not can_act(ctx, monster, definition) or
        not invisibility.visible_to(ctx, ctx:player(), monster) or
        not ctx:visible(origin.level_id, position.x, position.y, 7,
            origin.x, origin.y) then
        return false
    end

    return can_follow(ctx, monster, definition, elapsed_aut)
end

-- Check each neighbor in source adjacency order. A preceding strike may
-- relocate or kill the player, so the later neighbors are not preselected.
function opportunity.run(ctx, origin, destination, elapsed_aut)
    local player = ctx:player()

    for _, offset in ipairs(adjacent) do
        local monster = ctx:actor_at(origin.level_id,
            origin.x + offset[1], origin.y + offset[2])

        if monster and opportunity.eligible(ctx, monster,
            origin, destination, elapsed_aut) and
            ctx:random(streams.MELEE, 3) == 0 and
            targets.nearest(ctx, monster,
                ctx:get(monster, component.POSITION), 7) == player then
            local actor = ctx:get(monster, component.ACTOR)
            local definition = profile.definition(ctx, monster,
                catalog.get("monsters", actor.kind_id))
            local stored = ctx:get(monster, component.MONSTER_ENERGY)
            local attack_cost = energy.cost(ctx, {
                actor = ctx:id(monster),
                kind_id = definition.id,
                intent = intent.MELEE,
            })

            ctx:emit("combat", "The " .. definition.name ..
                " attacks as you move away!")
            melee.monster(ctx, monster, { player_moving = true })

            -- Reactions may change or remove the attacker during contact.
            -- Refund ten points from its live post-attack energy without
            -- exceeding the value captured before this strike.
            local remaining = ctx:get(monster, component.MONSTER_ENERGY)

            if remaining then
                remaining.points = math.min(stored.points,
                    remaining.points - attack_cost + 10)
                ctx:set(monster, component.MONSTER_ENERGY, remaining)
            end

            local health = ctx:get(player, component.HEALTH)
            local position = ctx:get(player, component.POSITION)
            local lives = ctx:get(player, component.EXTRA_LIVES)

            if not health or health.current <= 0 or
                lives and lives.pending_revival or
                not position or position.level_id ~= origin.level_id or
                position.x ~= origin.x or position.y ~= origin.y then
                return false
            end
        end
    end

    return true
end

return opportunity
