-- Source: shout.cc:noisy and noise_grid::propagate_noise.
local capabilities = require("constants.mutation_capabilities")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local terrain = require("constants.terrain")
local vision = require("policy.character.vision")
local statuses = require("policy.magic.effects.statuses.player")

local noise = {}

local base_attenuation = 850
local lowest_audible = 1000
local complete_attenuation = 250000

local walls = {
    [terrain.DNGN_ROCK_WALL] = true,
    [terrain.DNGN_STONE_WALL] = true,
    [terrain.DNGN_CLEAR_ROCK_WALL] = true,
    [terrain.DNGN_CLEAR_STONE_WALL] = true,
    [terrain.DNGN_CRYSTAL_WALL] = true,
    [terrain.DNGN_METAL_WALL] = true,
    [terrain.DNGN_SLIMY_WALL] = true,
}

local trees = {
    [terrain.DNGN_TREE] = true,
    [terrain.DNGN_DEMONIC_TREE] = true,
    [terrain.DNGN_PETRIFIED_TREE] = true,
    [terrain.DNGN_MANGROVE] = true,
}

local statues = {
    [terrain.DNGN_GRANITE_STATUE] = true,
    [terrain.DNGN_ORCISH_IDOL] = true,
}

-- Use one cell key for propagation and later hearing lookup.
local function key(x, y)
    return x .. "," .. y
end

-- Walls and doors reduce the propagated noise field before monsters compare it with their hearing state.
local function attenuation(feature)
    if not feature or feature == terrain.DNGN_PERMAROCK_WALL or
        feature == terrain.DNGN_CLEAR_PERMAROCK_WALL then
        return complete_attenuation
    end

    if walls[feature] then
        return base_attenuation * 12
    end

    if feature == terrain.DNGN_CLOSED_DOOR then
        return base_attenuation * 8
    end

    if trees[feature] then
        return base_attenuation * 3
    end

    if statues[feature] then
        return base_attenuation * 2
    end

    return base_attenuation
end

-- Sharp reversals cost more intensity so sound favours straighter corridors.
local function turn_angle(cell, dx, dy)
    if cell.dx == 0 and cell.dy == 0 then
        return 0
    end

    if dx == -cell.dx and dy == -cell.dy then
        return 4
    end

    return math.abs(cell.dx - dx) + math.abs(cell.dy - dy)
end

-- Requeue only a louder path to a cell; weaker revisits cannot improve hearing.
local function spread(ctx, level_id, cells, queue, current)
    local cost = attenuation(ctx:cell(level_id, current.x, current.y))

    if current.intensity - cost < lowest_audible then
        return
    end

    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = current.x + dx
                local y = current.y + dy

                if ctx:cell(level_id, x, y) then
                    local angle = turn_angle(current, dx, dy)
                    local turn_cost = math.floor(cost *
                        (100 + angle * 25) / 100)
                    local intensity = current.intensity - turn_cost
                    local location = key(x, y)
                    local previous = cells[location]

                    if intensity >= lowest_audible and
                        (not previous or intensity > previous.intensity) then
                        local next_cell = {
                            x = x,
                            y = y,
                            dx = dx,
                            dy = dy,
                            intensity = intensity,
                        }

                        cells[location] = next_cell
                        queue[#queue + 1] = next_cell
                    end
                end
            end
        end
    end
end

-- Dampen a visible player-side source before propagation so every listener sees one field.
function noise.adjust(ctx, origin, loudness)
    if loudness <= 0 then
        return 0
    end

    local player = ctx:player()
    local position = ctx:get(player, component.POSITION)

    if not position or position.level_id ~= origin.level_id or
        effects.sum(ctx, player, capabilities.NOISE_DAMPENING) == 0 or
        not ctx:visible(origin.level_id, position.x, position.y,
            vision.radius(ctx, player), origin.x, origin.y) then
        return loudness
    end

    -- Source div_rand_round: an odd loudness rounds up half the time.
    return math.floor(loudness / 2) +
        (loudness % 2 > ctx:random("ai", 2) and 1 or 0)
end

-- Expand intensity through terrain with a queue until no audible improvement remains.
function noise.propagate(ctx, origin, loudness)
    local cells = {}

    if loudness <= 0 or not ctx:cell(origin.level_id,
        origin.x, origin.y) then
        return cells
    end

    local first = {
        x = origin.x,
        y = origin.y,
        dx = 0,
        dy = 0,
        intensity = (loudness + 1) * 1000,
    }
    local queue = { first }
    local index = 1

    cells[key(first.x, first.y)] = first

    while index <= #queue do
        local current = queue[index]
        index = index + 1

        if cells[key(current.x, current.y)] == current then
            spread(ctx, origin.level_id, cells, queue, current)
        end
    end

    return cells
end

-- Missing cells are inaudible, avoiding a second terrain traversal for each monster.
function noise.at(cells, x, y)
    local cell = cells[key(x, y)]

    return cell and cell.intensity or 0
end

-- Shout mutations add two loudness units per effective level.
function noise.shout_volume(ctx, player)
    return 12 + 2 * effects.sum(ctx, player,
        capabilities.SHOUT_LEVEL)
end

-- A full alert records the noise origin and a finite pursuit deadline.
local function alert(ctx, monster, state, origin)
    state.behavior = "seek"
    state.target_x = origin.x
    state.target_y = origin.y
    state.memory_until_aut = ctx:aut() + 250
    ctx:set(monster, component.AI, state)
end

-- A wandering monster may investigate sound without changing to seek behaviour.
local function disturb(ctx, monster, state, origin)
    if state.behavior ~= "wander" then
        return
    end

    state.target_x = origin.x
    state.target_y = origin.y
    ctx:set(monster, component.AI, state)
end

-- Apply one propagated field to live monsters, excluding its producer.
local function heard_by_monsters(ctx, origin, cells, producer)
    local player = ctx:player()
    local player_position = ctx:get(player, component.POSITION)
    local source_visible = player_position and
        player_position.level_id == origin.level_id and
        ctx:visible(origin.level_id, player_position.x,
            player_position.y, vision.radius(ctx, player),
            origin.x, origin.y)

    for _, monster in ipairs(ctx:query({
        component.AI,
        component.POSITION,
        component.HEALTH,
    })) do
        if monster ~= producer and monster ~= player then
            local position = ctx:get(monster, component.POSITION)
            local health = ctx:get(monster, component.HEALTH)

            if health.current > 0 and
                position.level_id == origin.level_id and
                noise.at(cells, position.x, position.y) >= lowest_audible then
                local state = ctx:get(monster, component.AI)

                if source_visible then
                    local distance = math.max(
                        math.abs(origin.x - player_position.x),
                        math.abs(origin.y - player_position.y))
                    local chance = math.max(0,
                        100 - math.floor(90 * distance / 7))

                    if ctx:random("ai", 100) < chance then
                        alert(ctx, monster, state, origin)
                    else
                        disturb(ctx, monster, state, origin)
                    end
                else
                    disturb(ctx, monster, state, origin)
                end
            end
        end
    end
end

-- Suppress sound inside Silence before propagating one field to listeners and wake-up rules.
-- Example: a shout builds one noise field, then wakes or redirects monsters reached by that field.
function noise.emit(ctx, origin, loudness, producer)
    local player = ctx:player()
    local player_position = ctx:get(player, component.POSITION)
    local silence = statuses.silence_radius(ctx, player)

    if player_position and player_position.level_id == origin.level_id and
        silence >= 0 and
        math.max(math.abs(player_position.x - origin.x),
            math.abs(player_position.y - origin.y)) <= silence then
        return 0
    end

    local adjusted = noise.adjust(ctx, origin, loudness)
    local cells = noise.propagate(ctx, origin, adjusted)

    if adjusted > 0 then
        heard_by_monsters(ctx, origin, cells, producer)
    end

    return adjusted
end

return noise
