-- Adjacent fire effects transform water into steam and burn trees into floor;
-- the latter must also emit a terrain-destruction signal for other systems.

local harness = require("tests.harness")
local component = require("constants.component")
local terrain = require("constants.terrain")
local ids = require("ids.clouds")
local signals = require("constants.world_signals")

local test = {}

-- Keep cloud state separate from terrain so placement.at can inspect the
-- newly spawned cloud and forest fire can change its neighboring tree.
local function fixture()
    local states = {}
    local cells = {
        ["3:2"] = terrain.DNGN_SHALLOW_WATER,
        ["2:3"] = terrain.DNGN_TREE,
    }
    local next_id = 20
    local attempts = {}
    local ctx = {}

    -- Placement sees every cloud entity already created in the fixture.
    function ctx:query(required)
        if required[1] ~= component.WORLD_CLOUD then
            return {}
        end

        local entities = {}

        for entity in pairs(states) do
            entities[#entities + 1] = entity
        end

        return entities
    end

    -- Cloud lookups return saved state rather than a synthetic cloud at a cell.
    function ctx:get(entity)
        return states[entity]
    end

    -- Allocate a fresh cloud entity for each secondary placement.
    function ctx:create()
        next_id = next_id + 1
        return next_id
    end

    -- Accept only WORLD_CLOUD components so unrelated writes fail the fixture.
    function ctx:add(entity, kind, state)
        harness.equal(kind, component.WORLD_CLOUD)
        states[entity] = state
    end

    -- Use shallow water and tree at the two adjacent effect targets.
    function ctx:cell(_, x, y)
        return cells[x .. ":" .. y] or terrain.DNGN_FLOOR
    end

    -- Persist forest-fire terrain replacement for the final assertion.
    function ctx:set_cell(_, x, y, feature)
        cells[x .. ":" .. y] = feature
    end

    -- The tree blocks placement until forest fire destroys it.
    function ctx:walkable(_, x, y)
        return self:cell(1, x, y) ~= terrain.DNGN_TREE
    end

    -- The first eligible neighbor is always chosen by the seeded draw.
    function ctx:random(_, _)
        return 0
    end

    -- Attribute secondary fire clouds to the fixed player entity.
    function ctx:player()
        return 1
    end

    -- Keep cloud source ownership IDs stable across secondary placement.
    function ctx:id(entity)
        return entity
    end

    -- Resolve saved owner IDs back to fixture entities.
    function ctx:entity(id)
        return id
    end

    -- Ignore display messages while asserting saved cloud and terrain effects.
    function ctx:emit()
    end

    -- Terrain mutation is observable beyond the local cell map.
    function ctx:signal(name, value)
        harness.equal(name, signals.TERRAIN_DESTROY_ATTEMPT)
        attempts[#attempts + 1] = value
    end

    return ctx, cells, states, attempts
end

-- Both effects start at (2, 2), adjacent to the water and tree fixtures.
local function source(kind_id)
    return {
        kind_id = kind_id,
        level_id = 1,
        x = 2,
        y = 2,
        decay_aut = 40,
        spread_rate = 0,
        exclusion_radius = 0,
        source_actor_id = 1,
        kill_category = "KC_YOU",
        killer_type = "KILL_YOU_MISSILE",
        opaque = false,
        special_ints = {},
    }
end

-- Invoke pre-aging hooks directly so secondary placement is isolated from timer decay.
function test.run()
    local placement = require("policy.clouds.placement")
    local fire = require("policy.clouds.effects.fire")
    local forest = require("policy.clouds.effects.forest_fire")
    local ctx, cells, _, attempts = fixture()

    -- Run the pre-aging hook directly to isolate secondary cloud placement.
    fire.before_age(ctx, source(ids.CLOUD_FIRE))

    local _, steam = placement.at(ctx, 1, 3, 2)
    harness.equal(steam.kind_id, ids.CLOUD_STEAM,
        "fire next to water creates source steam")

    -- Burning the tree changes both terrain and the occupant cloud.
    forest.before_age(ctx, source(ids.CLOUD_FOREST_FIRE))

    local _, flame = placement.at(ctx, 1, 2, 3)
    harness.equal(cells["2:3"], terrain.DNGN_FLOOR,
        "forest fire destroys a flammable tree")
    harness.equal(flame.kind_id, ids.CLOUD_FOREST_FIRE,
        "burning tree carries the forest fire")
    harness.equal(#attempts, 1,
        "forest fire emits a typed terrain-destruction attempt")
end

return test
