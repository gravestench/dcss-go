-- Rats avoid miasma even without careful placement.

local harness = require("tests.harness")
local component = require("constants.component")
local ids = require("ids.clouds")
local monsters = require("ids.monsters")

local test = {}

-- Vary cloud kind and actor state on a fixed two-cell path to isolate danger decisions.
function test.run()
    local danger = require("policy.clouds.danger")
    -- Move one rat between fixed cells while swapping only the clouds or actor
    -- state needed for each danger exception.
    local destination = {
        level_id = 1,
        x = 2,
        y = 1,
    }
    local origin = {
        level_id = 1,
        x = 1,
        y = 1,
    }
    local destination_cloud = {
        kind_id = ids.CLOUD_MIASMA,
        level_id = 1,
        x = 2,
        y = 1,
    }
    local origin_cloud
    local ctx = {}

    -- Keep the rat distinct from the player for friendly-cloud handling.
    function ctx:player()
        return 99
    end

    -- Let danger inspect one destination cloud and one optional origin cloud.
    function ctx:query()
        return { 11, 12 }
    end

    -- The initial actor snapshot is a healthy rat; cloud entities occupy fixed cells.
    function ctx:get(entity, kind)
        if entity == 11 then
            return destination_cloud
        end

        if entity == 12 then
            return origin_cloud
        end

        if kind == component.ACTOR then
            return { kind_id = monsters.MONS_RAT }
        end

        if kind == component.HEALTH then
            return { current = 5, max = 5 }
        end

        if kind == component.POSITION then
            return origin
        end
    end

    harness.truthy(danger.avoids(ctx, 1, destination, false),
        "rats avoid miasma even without careful placement")

    -- Harmless dust never blocks movement, including careful placement.
    destination_cloud.kind_id = ids.CLOUD_DUST
    harness.falsy(danger.avoids(ctx, 1, destination, true),
        "harmless dust is safe during careful placement")

    destination_cloud.kind_id = ids.CLOUD_MIASMA
    -- Already standing in fire changes the cost of entering another hazard.
    origin_cloud = {
        kind_id = ids.CLOUD_FIRE,
        level_id = 1,
        x = 1,
        y = 1,
    }

    harness.falsy(danger.avoids(ctx, 1, destination, false),
        "monster may leave one harmful cloud for another")

    -- A friendly summon still avoids extinguishing the player's embers.
    origin_cloud = nil
    destination_cloud.kind_id = ids.CLOUD_EMBERS

    -- Return a friendly summon component to test its exception for player embers.
    function ctx:get(entity, kind)
        if entity == 11 then
            return destination_cloud
        end

        if kind == component.SUMMON then
            return { hostile = false }
        end

        if kind == component.ACTOR then
            return { kind_id = monsters.MONS_RAT }
        end

        if kind == component.POSITION then
            return origin
        end

        if kind == component.HEALTH then
            return { current = 5, max = 5 }
        end

        return nil
    end

    harness.truthy(danger.avoids(ctx, 1, destination, false),
        "a friendly summon does not snuff the player's embers")

    -- Cloud Mage has an explicit immunity that overrides ordinary danger.
    destination_cloud.kind_id = ids.CLOUD_FIRE

    -- Change only the actor kind to Cloud Mage for the innate immunity branch.
    function ctx:get(entity, kind)
        if entity == 11 then
            return destination_cloud
        end

        if kind == component.ACTOR then
            return {
                kind_id = monsters.MONS_CLOUD_MAGE,
            }
        end

        if kind == component.POSITION then
            return origin
        end

        return nil
    end

    harness.falsy(danger.avoids(ctx, 1, destination, true),
        "Cloud Mage may enter even harmful clouds")

    -- Low health makes delayed poison dangerous even when immediate damage is
    -- absent; the zero draw fixes the exposure estimate.
    destination_cloud.kind_id = ids.CLOUD_POISON

    -- Restore the low-HP rat so delayed poison is evaluated as dangerous.
    function ctx:get(entity, kind)
        if entity == 11 then
            return destination_cloud
        end

        if kind == component.ACTOR then
            return {
                kind_id = monsters.MONS_RAT,
            }
        end

        if kind == component.HEALTH then
            return {
                current = 5,
                max = 5,
            }
        end

        if kind == component.POSITION then
            return origin
        end
    end

    -- Pin the poison estimate at its low draw; five HP should still be unsafe.
    function ctx:random()
        return 0
    end

    harness.truthy(danger.avoids(ctx, 1, destination, false),
        "low-HP rat accounts for poison's delayed damage")
end

return test
