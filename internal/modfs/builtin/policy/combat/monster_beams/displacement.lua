local catalog = require("policy.catalog")
local component = require("constants.component")
local corpse_chunks = require("policy.combat.corpse_chunks")
local habitat = require("policy.combat.monster_habitat")
local monster_flags = require("constants.monster_flags")
local trajectory = require("policy.combat.trajectory")

local displacement = {}

local function stationary(ctx, target)
    local actor = ctx:get(target, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == monster_flags.STATIONARY then
            return true
        end
    end

    return false
end

local function habitable(ctx, target, level_id, x, y)
    if ctx:has(target, component.PLAYER) then
        return ctx:walkable(level_id, x, y)
    end

    return habitat.at(ctx, target, level_id, x, y)
end

local function body_weight(ctx, target)
    if ctx:has(target, component.PLAYER) then
        local player = ctx:get(target, component.PLAYER)
        local species = catalog.get("species", player.species_id)

        return corpse_chunks.maximum({ size_id = species.size })
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    return corpse_chunks.maximum(definition)
end

local function random_round(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if ctx:random("monster_spell", denominator) < remainder then
        return quotient + 1
    end

    return quotient
end

-- beam.cc:bolt::pull_actor regresses the incoming ray until the target
-- reaches an adjacent cell or finds solid, occupied, or unsuitable terrain.
function displacement.pull(ctx, caster, target, damage, incoming)
    if damage <= 0 or stationary(ctx, target) then
        return false
    end

    local source = incoming or ctx:get(caster, component.POSITION)
    local position = ctx:get(target, component.POSITION)

    if not source or not position or
        source.level_id ~= position.level_id then
        return false
    end

    local distance = math.max(math.abs(position.x - source.x),
        math.abs(position.y - source.y))

    if distance <= 1 then
        return false
    end

    local ray = trajectory.to_target(ctx, source.level_id,
        source.x, source.y, position.x, position.y, distance)
    local moved = false

    for index = #ray.path - 1, 1, -1 do
        local cell = ray.path[index]

        if ctx:actor_at(source.level_id, cell.x, cell.y) or
            not habitable(ctx, target, source.level_id,
                cell.x, cell.y) then
            break
        end

        ctx:move_actor(target, source.level_id, cell.x, cell.y)
        moved = true
    end

    return moved
end

-- beam.cc:bolt::knockback_actor advances on the incoming ray. Body size
-- may skip an individual push, while terrain or occupancy ends the push.
local function push_steps(ctx, caster, target, steps, roll, incoming)
    if stationary(ctx, target) then
        return false
    end

    local source = incoming or ctx:get(caster, component.POSITION)
    local position = ctx:get(target, component.POSITION)

    if not source or not position or
        source.level_id ~= position.level_id then
        return false
    end

    local ray = trajectory.trace(ctx, source.level_id,
        source.x, source.y, position.x, position.y, 7)
    local index

    for path_index, cell in ipairs(ray.path) do
        if cell.x == position.x and cell.y == position.y then
            index = path_index
            break
        end
    end

    if not index then
        return false
    end

    local weight = body_weight(ctx, target)
    local moved = false

    for _ = 1, steps do
        if ctx:random("monster_spell", roll) >= weight then
            index = index + 1
            local cell = ray.path[index]

            if not cell or
                ctx:actor_at(source.level_id, cell.x, cell.y) or
                not habitable(ctx, target, source.level_id,
                    cell.x, cell.y) then
                break
            end

            ctx:move_actor(target, source.level_id, cell.x, cell.y)
            moved = true
        end
    end

    return moved
end

function displacement.push(ctx, caster, target, damage, power, incoming)
    if damage <= 0 then
        return false
    end

    local steps = 2 + random_round(ctx, power, 50)
    local roll = 7 + math.floor(27 * power / 100)

    return push_steps(ctx, caster, target, steps, roll, incoming)
end

-- BEAM_WATER's source knockback does not require positive HP damage.
function displacement.wave(ctx, caster, target, incoming)
    return push_steps(ctx, caster, target, 1, 17, incoming)
end

return displacement
