-- Dead source attribution survives restore.

local harness = require("tests.harness")
local component = require("constants.component")
local ids = require("ids.clouds")
local terrain = require("constants.terrain")
local attribution = require("constants.cloud_attribution")

local test = {}

-- The source actor is intentionally absent: attribution must remain valid
-- after its entity is gone, while the cloud cell remains live.
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

    -- Enumerate saved cloud entities for validation, including malformed
    -- records injected by later cases.
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

    -- Return cloud state or player corrosion as requested, so restore checks
    -- can validate both cloud records and their related effect state.
    function ctx:get(entity, kind)
        if kind == component.CORROSION then
            return corrosion
        end

        return states[entity]
    end

    -- Keep fixture IDs stable in validation diagnostics for invalid saves.
    function ctx:id(entity)
        return entity
    end

    -- Let the validator compare saved clouds with floor versus blocked
    -- terrain without constructing a whole level.
    function ctx:walkable()
        return feature == terrain.DNGN_FLOOR
    end

    -- Return the active feature so cloud-terrain compatibility is validated
    -- against the same cell represented by walkability.
    function ctx:cell()
        return feature
    end

    -- Fix the turn unit used to validate remaining cloud duration.
    function ctx:aut()
        return 100
    end

    -- Identify the player whose corrosion state may be linked to clouds.
    function ctx:player()
        return 21
    end

    -- Allow each case to replace corrosion state without rebuilding the
    -- fixture, isolating save validation of that related component.
    return ctx, states, cloud, function(value)
        corrosion = value
    end
end

-- Require both rejection and a useful diagnostic substring, because a bad
-- saved cloud must identify the field that prevents restoration.
local function rejects(validator, ctx, needle)
    local okay, message = pcall(validator.validate, ctx)

    harness.falsy(okay, "invalid cloud save is rejected")
    harness.truthy(tostring(message):find(needle, 1, true),
        "save diagnostic names " .. needle)
end

-- Start from a valid saved cloud and mutate fields one at a time, proving
-- validation catches malformed terrain, lifetime, and related effect data.
function test.run()
    local validator = require("policy.save.clouds")
    local ctx, states, cloud, set_corrosion = fixture()

    validator.validate(ctx)
    harness.equal(cloud.source_actor_id, 900,
        "dead source attribution survives restore")

    -- Mutate one saved field at a time and restore it before the next case.
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

    -- Corrosion attached to the player is checked by the same save validator.
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

    -- A second cloud cannot claim the same level cell on restore.
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
