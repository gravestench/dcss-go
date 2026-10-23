-- Seal Doors tests whether a shut doorway would reduce player tension too much.
-- Source: mon-cast.cc:_should_force_door_shut and religion.cc:get_tension.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local component = require("constants.component")
local death = require("policy.death")
local doors = require("policy.inventory.doors")
local flags = require("constants.monster_flags")
local formulas = require("policy.character.formulas")
local confusion = require("policy.magic.player_confusion")
local targets = require("policy.ai.targets")
local vision = require("policy.character.vision")

local tension = {}

-- Catalog flags are lists, so test membership without assuming load order.
local function has_flag(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Compare a live sight line with a hypothetical doorway closure. The grid
-- itself must stay open until the resolver commits the decision.
local function visible(ctx, origin, sight, position, closed)
    if not closed then
        return ctx:visible_no_trans(origin.level_id, origin.x,
            origin.y, sight, position.x, position.y)
    end

    -- The host computes the normal no-trans shadowcast with these panels
    -- opaque. No real terrain or cloud is changed during the AI check.
    return ctx:visible_no_trans_with_blocked(origin.level_id,
        origin.x, origin.y, sight, position.x, position.y, closed)
end

-- Tension treats a hostile monster as danger and an allied monster as
-- relief. Scale its XP by health and active boons before comparing scenes.
local function monster_value(ctx, monster)
    local actor = ctx:get(monster, component.ACTOR)
    local health = ctx:get(monster, component.HEALTH)

    if not actor or not health or health.current <= 0 or
        health.max <= 0 then
        return 0, false
    end

    -- Charm changes the monster's effective side in mons_attitude.
    local attitude = targets.attitude(ctx, monster)

    if attitude == attitudes.NEUTRAL or
        attitude == attitudes.GOOD_NEUTRAL then
        return 0, false
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if has_flag(definition.flags, flags.NO_THREAT) then
        return 0, attitude == attitudes.HOSTILE
    end

    local value = death.experience(definition, health.max, true)

    value = math.floor(value * health.current / health.max)

    if ctx:get(monster, component.PARALYSIS) then
        return 0, attitude == attitudes.HOSTILE
    end

    local confusion = ctx:get(monster, component.MONSTER_CONFUSION)

    if confusion then
        value = math.floor(value / 2)
    end

    local boons = ctx:get(monster, component.MONSTER_BOONS)

    if boons then
        if boons.haste_aut and boons.haste_aut > 0 then
            value = math.floor(value * 3 / 2)
        end

        if boons.might_aut and boons.might_aut > 0 then
            value = math.floor(value * 5 / 4)
        end
    end

    if attitude == attitudes.FRIENDLY then
        value = -value
    end

    return value, attitude == attitudes.HOSTILE
end

-- Evaluate the player's local threat from one viewpoint, optionally after
-- a doorway actor has been pushed to a candidate square.
local function score(ctx, player, origin, closed, moved, destination)
    local health = ctx:get(player, component.HEALTH)
    local progress = ctx:get(player, component.PROGRESSION)

    if not health or not progress then
        return 0
    end

    local sight = vision.radius(ctx, player)
    local total = 0
    local nearby = false

    for _, monster in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if monster ~= player then
            local position = monster == moved and destination or
                ctx:get(monster, component.POSITION)

            if position and position.level_id == origin.level_id and
                visible(ctx, origin, sight, position, closed) then
                local value, hostile = monster_value(ctx, monster)

                total = total + value
                nearby = nearby or hostile
            end
        end
    end

    if not nearby then
        return 0
    end

    local scaled = math.floor(total * 2 * health.max /
        math.max(health.max + health.current, 1))
    local character = ctx:get(player, component.PLAYER)
    local species = character and catalog.get("species",
        character.species_id)
    local needed = formulas.experience_needed(progress.level,
        species and species.xp or 1)
    local divisor = 1 + math.ceil(math.sqrt(needed / 30))

    scaled = math.floor(scaled / divisor)

    if ctx:level_branch(origin.level_id) == "BRANCH_ABYSS" then
        scaled = scaled < 2 and 2 or math.floor(scaled * 3 / 2)
    end

    local paralysis = ctx:get(player, component.PLAYER_PARALYSIS)

    if paralysis and paralysis.remaining_aut > 0 then
        return math.max(1, scaled * 10)
    end

    if confusion.active(ctx, player) then
        scaled = scaled * 2
    end

    local player_slow = ctx:get(player, component.PLAYER_SLOW)

    if player_slow and player_slow.remaining_aut > 0 then
        scaled = math.floor(scaled * 3 / 2)
    end

    local durations = ctx:get(player, component.DURATIONS)

    if durations then
        if durations.haste_aut and durations.haste_aut > 0 then
            scaled = math.floor(scaled * 2 / 3)
        end
    end

    return math.max(0, scaled)
end

-- The source's push search maximizes post-closure tension for both the player
-- and non-hostile doorway actors; ties keep the first available square.
function tension.best_push(ctx, actor, group, panel, excluded)
    local player = ctx:player()
    local origin = ctx:get(player, component.POSITION)
    local best
    local best_score = -1

    for _, target in ipairs(doors.push_targets(ctx,
        origin.level_id, panel, excluded)) do
        if not ctx:actor_at(origin.level_id,
            target.x, target.y) then
            local pushed = {
                level_id = origin.level_id,
                x = target.x,
                y = target.y,
            }
            local viewpoint = actor == player and pushed or origin
            local value = score(ctx, player, viewpoint,
                group, actor, pushed)

            if value > best_score then
                best = target
                best_score = value
            end
        end
    end

    return best, best_score
end

-- Source chooses the player's push square with maximum post-closure tension.
-- Its exact inequality also rejects a zero-to-zero change.
function tension.allows_close(ctx, player, group)
    local origin = ctx:get(player, component.POSITION)
    local current = score(ctx, player, origin)
    local closed = score(ctx, player, origin, group)

    for _, panel in ipairs(group) do
        if panel.x == origin.x and panel.y == origin.y then
            local _, best_tension = tension.best_push(ctx, player,
                group, panel, doors.excluded(group))
            closed = best_tension

            break
        end
    end

    return closed >= 0 and 1 + current * 66 <= closed * 100
end

-- Divine wrath and door sealing ask the same live question: how dangerous
-- are the visible monsters to this player right now? Keep the source score
-- in one owner so status changes affect both decisions together.
function tension.current(ctx, player)
    local origin = ctx:get(player, component.POSITION)

    return score(ctx, player, origin)
end

return tension
