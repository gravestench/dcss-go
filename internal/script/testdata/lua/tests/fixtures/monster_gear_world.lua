-- Monster gear policy tests need real ECS actors without building a complete
-- Go floor. This fixture supplies only the geometry and RNG methods normally
-- owned by that floor; production factory and item rules remain unchanged.
local component = require("constants.component")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local fixture = {}

-- Allocate a fresh player history for each case. A high gear roll misses
-- one-in-N grants while leaving item generation on its deterministic draw.
function fixture.new(ctx, high_gear_roll)
    local world = setmetatable({}, { __index = ctx })
    local player = ctx:create()

    ctx:add(player, component.PLAYER_UNIQUE_HISTORY, {
        status = {},
        monsters = {},
        pan_states = {},
        choices = {},
        boris_killed = false,
    })

    -- The player owns unique item history in both tests and production.
    function world:player()
        return player
    end

    -- Keep monster gear draws controllable without changing other saved
    -- streams; every returned value remains inside its requested bound.
    function world:random(stream, bound)
        harness.truthy(bound > 0, "monster gear RNG bound")

        if stream == streams.MONSTER_GEAR and high_gear_roll then
            return bound - 1
        end

        return 0
    end

    -- The test's open floor has no habitat or collision restrictions.
    function world:walkable()
        return true
    end

    -- A blocked placement checks that gear is not claimed prematurely.
    function world:actor_at()
        return self.blocked and 1 or nil
    end

    -- All trial cells are plain ground for land monsters.
    function world:cell()
        return terrain.DNGN_FLOOR
    end

    -- The real factory owns actor creation; the fixture only records its
    -- position the way the Go level would.
    function world:place_actor(entity, level_id, x, y)
        ctx:add(entity, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    return world, player
end

-- Inspect the real carried item edge and unique component. A cosmetic
-- loadout declaration alone cannot satisfy the gear tests.
function fixture.signature_item(ctx, monster, artefact_id)
    for _, entity in ipairs(ctx:query({
        component.ITEM,
        component.CARRIED_BY,
        component.ITEM_ARTEFACT,
    })) do
        local carrier = ctx:get(entity, component.CARRIED_BY)
        local artefact = ctx:get(entity, component.ITEM_ARTEFACT)

        if carrier.holder == monster and
            artefact.unique_id == artefact_id then
            return entity
        end
    end

    return nil
end

return fixture
