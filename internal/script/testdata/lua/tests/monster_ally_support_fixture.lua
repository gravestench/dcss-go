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

-- LOS_NO_TRANS is a separate grid query in production. Rule tests without
-- walls let it agree with their ordinary visibility result.
function game_methods.visible_no_trans()
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

-- Focused actor tests use a sparse synthetic Dungeon floor rather than a
-- generated grid record; its branch-local depth is the first floor.
function game_methods.level_depth()
    return 1
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

-- Reach and projectile rules distinguish blocked terrain from actors.
-- The sparse fixture's wall markers mimic the production grid predicates.
function game_methods.solid(game, _, x, y)
    return game.walls[x .. ":" .. y] or false
end

-- Ordinary fixture walls are opaque; the production grid also handles
-- clear walls and grates through their real terrain definitions.
function game_methods.opaque(game, _, x, y)
    return game.walls[x .. ":" .. y] or false
end

-- Temporary terrain spells write the same test grid they later read.
-- Keeping this in the shared fixture avoids a one-off spell stub.
function game_methods.set_cell(game, _, x, y, feature)
    game.cells[x .. ":" .. y] = feature
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

-- Relocation tests keep the production POSITION schema and expose the
-- same movement result without requiring a generated level grid.
function game_methods.move_actor(game, entity, level_id, x, y)
    game.base:set(entity, component.POSITION, {
        level_id = level_id,
        x = x,
        y = y,
    })
end

-- A mirror swaps two occupied cells atomically in the production grid.
-- This sparse fixture applies both validated destinations to real ECS state.
function game_methods.move_actors(game, moves)
    for _, move in ipairs(moves) do
        game_methods.move_actor(game, move.actor, move.level_id,
            move.x, move.y)
    end
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

-- Give focused rule tests a real observer so message visibility uses the
-- same player lookup and position contract as the game session.
function fixture.observed_context(ctx)
    local player = ctx:create()

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    return fixture.context(ctx, player)
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
