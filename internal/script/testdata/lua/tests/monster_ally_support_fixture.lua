local component = require("constants.component")

local fixture = {}
local game_methods = {}

-- The game has one player, but this target family never casts on that actor.
function game_methods.player(game)
    return game.player_entity
end

-- Eligibility uses live sight. Individual wall cases use the beam trace
-- below so tests distinguish visibility from projectile interception.
function game_methods.visible()
    return true
end

-- A sparse wall map is enough to exercise production beam geometry while
-- ECS components stay in the actual test world.
function game_methods.walkable(game, _, x, y)
    return not game.walls[x .. ":" .. y]
end

-- Ray tracing observes all positioned actors, including ineligible ones
-- that could intercept a beneficial beam before it reaches an ally.
function game_methods.actor_at(game, level_id, x, y)
    for _, entity in ipairs(game.base:query({
        component.ACTOR,
        component.POSITION,
    })) do
        local position = game.base:get(entity, component.POSITION)

        if position.level_id == level_id and position.x == x and
            position.y == y then
            return entity
        end
    end

    return nil
end

-- Forward unmodified ECS, RNG, and event methods to the real test runtime.
local function lookup(game, key)
    return game_methods[key] or game.base[key]
end

-- Each test owns its walls and player while sharing the production world.
function fixture.context(ctx, player)
    return setmetatable({
        base = ctx,
        player_entity = player,
        walls = {},
    }, {
        __index = lookup,
    })
end

-- Create only the components the spell targeting and status owners read.
function fixture.actor(ctx, kind_id, x, y, health)
    local entity = ctx:create()
    local current = health or 10

    ctx:add(entity, component.ACTOR, {
        kind_id = kind_id,
        speed = 10,
    })

    ctx:add(entity, component.HEALTH, {
        current = current,
        max = 100,
    })

    ctx:add(entity, component.POSITION, {
        level_id = 1,
        x = x,
        y = y,
    })

    return entity
end

return fixture
