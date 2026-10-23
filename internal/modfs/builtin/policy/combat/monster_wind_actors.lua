-- Wind Blast moves actors farthest first so a creature behind another can
-- occupy the cell the front creature just vacated. The source applies
-- collision damage after the push pass and landing traps at the end.
local catalog = require("policy.catalog")
local component = require("constants.component")
local defense = require("policy.combat.monster_defense")
local dislodge = require("policy.combat.dislodge")
local display = require("policy.combat.monster_support.display")
local inventory_equipment = require("policy.inventory.equipment")
local fighter = require("policy.combat.fighter")
local flags = require("constants.monster_flags")
local geometry = require("policy.combat.monster_wind_geometry")
local habitat = require("policy.combat.monster_habitat")
local monster_health = require("policy.combat.monster_health")
local player_health = require("policy.combat.player_health")
local passwall = require("policy.magic.effects.translocation.passwall")
local relocation = require("policy.world.monster_relocation")
local translocation = require("policy.scrolls.translocation")
local size = require("constants.size")
local streams = require("constants.rng_streams")
local traps = require("policy.traps.activation")
local vampire = require("policy.character.vampire")

local actors = {}

-- Flags on the immutable monster definition govern whether wind can move
-- or hurt this body; the current position and HP stay on the entity.
local function has_flag(ctx, entity, wanted)
    if ctx:has(entity, component.PLAYER) then
        return false
    end

    local actor = ctx:get(entity, component.ACTOR)
    local definition = actor and catalog.get("monsters", actor.kind_id)

    for _, flag in ipairs(definition and definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Distance, power, and body size independently change the number of
-- attempted outward steps. A zero result leaves the actor in place.
local function push_distance(ctx, source, entity, power, stream)
    local bound = math.floor(power / 20)
    local distance = 1

    if bound > 0 then
        distance = distance + ctx:random(stream, bound)
    end

    local rank = dislodge.body_rank(ctx, entity)

    if rank < size.rank[size.MEDIUM] then
        distance = distance + 1
    elseif rank > size.rank[size.LARGE] then
        distance = math.floor(distance / 2)
    elseif rank > size.rank[size.MEDIUM] then
        distance = distance - 1
    end

    local position = ctx:get(entity, component.POSITION)
    local range = geometry.distance(source, position)

    if range > 5 then
        distance = distance - 2
    elseif range > 2 then
        distance = distance - 1
    end

    return math.max(0, distance)
end

-- Solid cells, occupied cells, and unsuitable habitat all block a push.
local function can_enter(ctx, entity, level_id, cell)
    if ctx:actor_at(level_id, cell.x, cell.y) or
        not ctx:walkable(level_id, cell.x, cell.y) then
        return false
    end

    if ctx:has(entity, component.PLAYER) then
        return translocation.can_land(ctx, entity,
            level_id, cell.x, cell.y)
    end

    return habitat.at(ctx, entity, level_id,
        cell.x, cell.y)
end

-- Source stop_delay runs after each forced player step. A saved equipment,
-- passwall, or blood ritual must not finish after that displacement.
local function interrupt_player_delay(ctx, player)
    if ctx:has(player, component.EQUIPMENT_DELAY) then
        ctx:emit("combat", inventory_equipment.cancel(ctx, player))
    end

    if ctx:has(player, component.PASSWALL_DELAY) then
        ctx:emit("combat", passwall.cancel(ctx, player))
    end

    local blood = ctx:get(player, component.VAMPIRE)

    if blood and blood.ritual_remaining_aut > 0 then
        ctx:emit("combat", vampire.interrupt(ctx, player))
    end
end

-- Monster relocation releases old spatial links; player movement uses
-- the shared grid service directly. Neither path spends an actor action.
local function move(ctx, entity, level_id, cell)
    if ctx:has(entity, component.PLAYER) then
        ctx:move_actor(entity, level_id, cell.x, cell.y)
        interrupt_player_delay(ctx, entity)
    else
        relocation.move(ctx, entity, level_id, cell.x, cell.y)
    end
end

-- Select every alive body in the source solid-LOS cone, then sort by
-- distance so movement order does not depend on ECS query order.
local function candidates(ctx, caster, source, aim, radius)
    local selected = {}

    for _, entity in ipairs(ctx:query({
        component.POSITION,
        component.HEALTH,
    })) do
        local position = ctx:get(entity, component.POSITION)
        local health = ctx:get(entity, component.HEALTH)
        local distance = geometry.distance(source, position)

        if entity ~= caster and health.current > 0 and
            position.level_id == source.level_id and
            distance > 0 and distance <= radius and
            not has_flag(ctx, entity, flags.STATIONARY) and
            not dislodge.resists(ctx, entity) and
            geometry.in_cone(source, aim, position) and
            geometry.visible_solid(ctx, source, position) then
            selected[#selected + 1] = {
                entity = entity,
                origin = position,
                distance = distance,
            }
        end
    end

    table.sort(selected, function(first, second)
        if first.distance ~= second.distance then
            return first.distance > second.distance
        end

        return ctx:id(first.entity) < ctx:id(second.entity)
    end)

    return selected
end

-- Follow the outward ray and try same-radius neighboring cells when its
-- next cell is blocked. Record an unresolved obstruction for collision.
local function push_one(ctx, caster, source, candidate, power, stream)
    local entity = candidate.entity
    local remaining = push_distance(ctx, source, entity, power, stream)
    local moved = false
    local blocked

    while remaining > 0 do
        local current = ctx:get(entity, component.POSITION)
        local next_cell = geometry.next_cell(ctx, source, current)

        if not next_cell then
            break
        end

        local destination = next_cell

        if not can_enter(ctx, entity, source.level_id, destination) then
            destination = nil

            for _, cell in ipairs(geometry.alternates(source,
                current, next_cell)) do
                if can_enter(ctx, entity, source.level_id, cell) then
                    destination = cell

                    break
                end
            end
        end

        if not destination then
            blocked = next_cell

            break
        end

        move(ctx, entity, source.level_id, destination)
        remaining = remaining - 1
        moved = true
    end

    if moved and entity ~= ctx:player() then
        local energy = ctx:get(entity, component.MONSTER_ENERGY)

        if energy then
            -- Source check_speed clamps a negative speed_increment at
            -- the next actor check. Keep the saved ECS value valid now.
            energy.points = math.max(0, energy.points - 4 -
                ctx:random(stream, 6))
            ctx:set(entity, component.MONSTER_ENERGY, energy)
        end
    end

    return moved, blocked
end

-- Armour is rolled separately for each body struck in a collision.
local function collision_damage(ctx, caster, victim, power, stream)
    if has_flag(ctx, victim, flags.INSUBSTANTIAL) or
        has_flag(ctx, victim, flags.PROJECTILE) then
        return
    end

    local sides = 1 + math.floor(power / 10)
    local raw = 2 + ctx:random(stream, sides) +
        ctx:random(stream, sides)
    local armour

    if ctx:has(victim, component.PLAYER) then
        armour = fighter.defense(ctx).ac
    else
        local actor = ctx:get(victim, component.ACTOR)
        local definition = catalog.get("monsters", actor.kind_id)

        armour = defense.armour(ctx, victim, definition)
    end

    local amount = math.max(0,
        raw - ctx:random(stream, armour + 1))

    if ctx:has(victim, component.PLAYER) then
        player_health.damage(ctx, victim, amount, false, caster)
    else
        monster_health.damage(ctx, victim, amount, caster)
    end
end

-- A collision with another actor hurts both; a wall hurts only the
-- pushed actor. Callers may use their own stream for the physical rolls.
function actors.collisions(ctx, caster, blocked, power, stream)
    stream = stream or streams.MONSTER_SPELL

    for _, contact in ipairs(blocked) do
        local victim = contact.entity
        local health = ctx:get(victim, component.HEALTH)

        if health and health.current > 0 and
            not has_flag(ctx, victim, flags.INSUBSTANTIAL) and
            not has_flag(ctx, victim, flags.PROJECTILE) then
            local other = ctx:actor_at(contact.level_id,
                contact.cell.x, contact.cell.y)

            -- Source actor::collide ignores both bodies when the obstacle
            -- is a projectile, even though that projectile blocked motion.
            if not other or not has_flag(ctx, other,
                flags.PROJECTILE) then
                if other and other ~= victim then
                    ctx:emit("combat", "The " ..
                        display.name(ctx, victim) ..
                        " collides with the " ..
                        display.name(ctx, other) .. "!")
                    collision_damage(ctx, caster, other, power, stream)
                else
                    ctx:emit("combat", "The " ..
                        display.name(ctx, victim) ..
                        " slams into an obstruction!")
                end

                collision_damage(ctx, caster, victim, power, stream)
            end
        end
    end
end

-- Run landing effects after collision resolution, matching the source's
-- deferred trap pass for wind-displaced actors.
function actors.land(ctx, moved)
    for _, candidate in ipairs(moved) do
        local health = ctx:get(candidate.entity, component.HEALTH)

        if health and health.current > 0 then
            traps.enter(ctx, candidate.entity, candidate.origin,
                ctx:get(candidate.entity, component.POSITION))
        end
    end
end

-- Return deferred collision and landing lists to the spell coordinator.
-- Ordinary spells keep MONSTER_SPELL; card effects may supply CARDS.
function actors.push(ctx, caster, source, aim, radius, power, stream)
    stream = stream or streams.MONSTER_SPELL

    local moved = {}
    local blocked = {}

    for _, candidate in ipairs(candidates(ctx, caster,
        source, aim, radius)) do
        local did_move, obstacle = push_one(ctx, caster, source,
            candidate, power, stream)

        if did_move then
            moved[#moved + 1] = candidate

            if candidate.entity == ctx:player() then
                ctx:emit("combat", "You are blown backwards!")
            else
                ctx:emit("combat", "The " ..
                    display.name(ctx, candidate.entity) ..
                    " is blown away by the wind!")
            end
        end

        if obstacle then
            blocked[#blocked + 1] = {
                entity = candidate.entity,
                level_id = source.level_id,
                cell = obstacle,
            }
        end
    end

    return moved, blocked
end

return actors
