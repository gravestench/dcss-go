local harness = require("tests.harness")
local component = require("constants.component")
local ids = require("ids.clouds")
local terrain = require("constants.terrain")
local attribution = require("constants.cloud_attribution")

local test = {}

local function fixture()
    local cloud = {
        kind_id = ids.CLOUD_FIRE,
        level_id = 1,
        x = 3,
        y = 2,
        decay_aut = 30,
        spread_rate = 0,
        exclusion_radius = 0,
        source_actor_id = 900,
        kill_category = attribution.PLAYER,
        killer_type = attribution.PLAYER_MISSILE,
        opaque = false,
        special_ints = {},
    }
    local states = {
        [11] = cloud,
    }
    local corrosion
    local feature = terrain.DNGN_FLOOR
    local ctx = {}

    function ctx:query(kinds)
        if kinds[1] == component.WORLD_CLOUD then
            local entities = {}

            for entity in pairs(states) do
                entities[#entities + 1] = entity
            end

            return entities
        end

        if kinds[1] == component.CORROSION and corrosion then
            return { 21 }
        end

        return {}
    end

    function ctx:get(entity, kind)
        if kind == component.CORROSION then
            return corrosion
        end

        return states[entity]
    end

    function ctx:id(entity)
        return entity
    end

    function ctx:walkable()
        return feature == terrain.DNGN_FLOOR
    end

    function ctx:cell()
        return feature
    end

    function ctx:aut()
        return 100
    end

    function ctx:player()
        return 21
    end

    return ctx, states, cloud, function(value)
        corrosion = value
    end
end

local function rejects(validator, ctx, needle)
    local okay, message = pcall(validator.validate, ctx)

    harness.falsy(okay, "invalid cloud save is rejected")
    harness.truthy(tostring(message):find(needle, 1, true),
        "save diagnostic names " .. needle)
end

function test.run()
    local validator = require("policy.save.clouds")
    local ctx, states, cloud, set_corrosion = fixture()

    validator.validate(ctx)
    harness.equal(cloud.source_actor_id, 900,
        "dead source attribution survives restore")

    cloud.kind_id = "CLOUD_NOT_REGISTERED"
    rejects(validator, ctx, "unknown kind")
    cloud.kind_id = ids.CLOUD_FIRE

    cloud.kind_id = ids.CLOUD_INK
    cloud.opaque = true
    rejects(validator, ctx, "ineligible for terrain")
    cloud.kind_id = ids.CLOUD_FIRE
    cloud.opaque = false

    cloud.decay_aut = 0
    rejects(validator, ctx, "decay")
    cloud.decay_aut = 30

    cloud.opaque = true
    rejects(validator, ctx, "opacity")
    cloud.opaque = false

    set_corrosion({
        remaining_aut = 0,
        stacks = 1,
    })
    rejects(validator, ctx, "corrosion")

    set_corrosion({
        remaining_aut = 20,
        stacks = 2,
    })
    validator.validate(ctx)

    states[12] = {
        kind_id = ids.CLOUD_DUST,
        level_id = 1,
        x = 3,
        y = 2,
        decay_aut = 30,
        spread_rate = 0,
        exclusion_radius = 0,
        source_actor_id = 0,
        kill_category = attribution.OTHER,
        killer_type = attribution.MISC,
        opaque = false,
        special_ints = {},
    }

    rejects(validator, ctx, "duplicate")
end

return test
