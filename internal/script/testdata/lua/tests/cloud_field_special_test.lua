local harness = require("tests.harness")
local component = require("constants.component")
local terrain = require("constants.terrain")
local ids = require("ids.clouds")
local signals = require("constants.world_signals")

local test = {}

local function fixture()
    local states = {}
    local cells = {
        ["3:2"] = terrain.DNGN_SHALLOW_WATER,
        ["2:3"] = terrain.DNGN_TREE,
    }
    local next_id = 20
    local attempts = {}
    local ctx = {}

    function ctx:query()
        local entities = {}

        for entity in pairs(states) do
            entities[#entities + 1] = entity
        end

        return entities
    end

    function ctx:get(entity)
        return states[entity]
    end

    function ctx:create()
        next_id = next_id + 1
        return next_id
    end

    function ctx:add(entity, kind, state)
        harness.equal(kind, component.WORLD_CLOUD)
        states[entity] = state
    end

    function ctx:cell(_, x, y)
        return cells[x .. ":" .. y] or terrain.DNGN_FLOOR
    end

    function ctx:set_cell(_, x, y, feature)
        cells[x .. ":" .. y] = feature
    end

    function ctx:walkable(_, x, y)
        return self:cell(1, x, y) ~= terrain.DNGN_TREE
    end

    function ctx:random(_, _)
        return 0
    end

    function ctx:player()
        return 1
    end

    function ctx:id(entity)
        return entity
    end

    function ctx:entity(id)
        return id
    end

    function ctx:emit()
    end

    function ctx:signal(name, value)
        harness.equal(name, signals.TERRAIN_DESTROY_ATTEMPT)
        attempts[#attempts + 1] = value
    end

    return ctx, cells, states, attempts
end

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

function test.run()
    local placement = require("policy.clouds.placement")
    local fire = require("policy.clouds.effects.fire")
    local forest = require("policy.clouds.effects.forest_fire")
    local ctx, cells, _, attempts = fixture()

    fire.before_age(ctx, source(ids.CLOUD_FIRE))

    local _, steam = placement.at(ctx, 1, 3, 2)
    harness.equal(steam.kind_id, ids.CLOUD_STEAM,
        "fire next to water creates source steam")

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
