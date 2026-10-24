-- A small deterministic floor checks the production corruption policy,
-- saved nexus schema, grid protection, and clock without duplicating them.
local component = require("constants.component")
local harness = require("tests.harness")
local saved = require("policy.save.lugonu_corruption")
local terrain = require("constants.terrain")
local terrain_pass = require("policy.world.lugonu_corruption.terrain")
local world = require("policy.world.lugonu_corruption")

local test = {}

-- The grid fixture implements only the engine's public cell service;
-- ECS components, terrain policy, and save validation remain production.
local function floor(ctx)
    local game = setmetatable({}, { __index = ctx })
    local grid = {}

    for y = 0, 8 do
        grid[y] = {}

        for x = 0, 8 do
            grid[y][x] = (x == 0 or y == 0 or x == 8 or y == 8) and
                terrain.DNGN_ROCK_WALL or terrain.DNGN_FLOOR
        end
    end

    grid[4][6] = terrain.DNGN_STONE_STAIRS_DOWN_I

    function game:level_size(level_id)
        if level_id == 1 then
            return 9, 9
        end

        return nil, nil
    end

    function game:cell(level_id, x, y)
        if level_id ~= 1 or not grid[y] then
            return nil
        end

        return grid[y][x]
    end

    function game:set_cell(level_id, x, y, feature)
        harness.equal(level_id, 1)
        grid[y][x] = feature
    end

    function game:walkable(level_id, x, y)
        local feature = self:cell(level_id, x, y)

        return feature == terrain.DNGN_FLOOR or
            feature == terrain.DNGN_ALTAR_LUGONU
    end

    function game:actor_at()
        return nil
    end

    function game:random(_, bound)
        if bound == 4000 then
            return 3999
        end

        return 0
    end

    return game, grid
end

-- The first 300-aut effect batch ages its clock immediately. A later
-- action on another floor leaves that clock alone, and reload accepts it.
local function nexus_clock(ctx)
    local game, grid = floor(ctx)
    local player = ctx:create()

    function game:player()
        return player
    end

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 4,
        y = 4,
    })

    world.apply(game, player, 300)

    local markers = game:query({
        component.LUGONU_CORRUPTION_NEXUS,
    })

    harness.equal(#markers, 1)
    harness.equal(grid[4][4], terrain.DNGN_FLOOR)
    harness.equal(grid[4][6], terrain.DNGN_STONE_STAIRS_DOWN_I)
    harness.truthy(world.corrupted(game, 1))
    saved.validate(game)

    local state = game:get(markers[1],
        component.LUGONU_CORRUPTION_NEXUS)

    harness.equal(state.remaining_aut, 420)
    world.advance(game, { level_id = 2, elapsed_aut = 10 })
    harness.equal(game:get(markers[1],
        component.LUGONU_CORRUPTION_NEXUS).remaining_aut, 420)
    world.advance(game, { level_id = 1, elapsed_aut = 10 })
    harness.equal(game:get(markers[1],
        component.LUGONU_CORRUPTION_NEXUS).remaining_aut, 410)
end

-- A fixed proto draw requests rock, while a second draw allows the
-- wall; nearby floor changes permanently without replacing the player.
local function terrain_change(ctx)
    local game, grid = floor(ctx)

    grid[3][5] = terrain.DNGN_ALTAR_LUGONU

    function game:random(_, bound)
        if bound == 4001 then
            return 3000
        end

        if bound == 2 then
            return 1
        end

        if bound == 3 then
            return 1
        end

        return 0
    end

    terrain_pass.apply(game, 1, 4, 4, {
        { x = 4, y = 4 },
        { x = 3, y = 4 },
    })

    harness.equal(grid[4][4], terrain.DNGN_FLOOR)
    harness.equal(grid[4][3], terrain.DNGN_FLOOR)
    harness.equal(grid[4][6], terrain.DNGN_STONE_STAIRS_DOWN_I)
    harness.equal(grid[4][5], terrain.DNGN_ROCK_WALL)
    harness.equal(grid[3][5], terrain.DNGN_ALTAR_LUGONU)
end

-- Keep two checks in one fixture to reuse the exact same public grid
-- contract while still exercising the separate world and terrain owners.
function test.run(ctx)
    nexus_clock(ctx)
    terrain_change(ctx)
end

return test
