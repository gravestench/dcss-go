local component = require("constants.component")
local branches = require("ids.branches")
local terrain = require("constants.terrain")

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

-- Rule tests start at aut zero; the full game test verifies advancing time.
function game_methods.aut()
    return 0
end

-- The current playable generator and these rule tests use Dungeon floors.
-- Shadow Creatures asks the grid for that branch before choosing a roster.
function game_methods.level_branch()
    return branches.BRANCH_DUNGEON
end

-- A sparse wall map is enough to exercise production beam geometry while
-- ECS components stay in the actual test world.
function game_methods.walkable(game, _, x, y)
    return not game.walls[x .. ":" .. y]
end

-- A small terrain override lets habitat tests distinguish a passable water
-- cell from ordinary floor without copying the production grid service.
function game_methods.cell(game, _, x, y)
    return game.cells[x .. ":" .. y] or terrain.DNGN_FLOOR
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

-- A successful placement writes the same POSITION component that the
-- production grid service owns; this fixture has no physical level grid.
function game_methods.place_actor(game, entity, level_id, x, y)
    game.base:add(entity, component.POSITION, {
        level_id = level_id,
        x = x,
        y = y,
    })
end

-- Summon expiry removes spatial occupancy before destroying the entity.
function game_methods.remove_actor(game, entity)
    game.base:remove(entity, component.POSITION)
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
        cells = {},
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
