local harness = require("tests.harness")
local component = require("constants.component")
local ids = require("ids.clouds")
local monsters = require("ids.monsters")

local test = {}

function test.run()
    local danger = require("policy.clouds.danger")
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

    function ctx:player()
        return 99
    end

    function ctx:query()
        return { 11, 12 }
    end

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

    destination_cloud.kind_id = ids.CLOUD_DUST
    harness.falsy(danger.avoids(ctx, 1, destination, true),
        "harmless dust is safe during careful placement")

    destination_cloud.kind_id = ids.CLOUD_MIASMA
    origin_cloud = {
        kind_id = ids.CLOUD_FIRE,
        level_id = 1,
        x = 1,
        y = 1,
    }

    harness.falsy(danger.avoids(ctx, 1, destination, false),
        "monster may leave one harmful cloud for another")

    origin_cloud = nil
    destination_cloud.kind_id = ids.CLOUD_EMBERS

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

    destination_cloud.kind_id = ids.CLOUD_FIRE

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

    destination_cloud.kind_id = ids.CLOUD_POISON

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

    function ctx:random()
        return 0
    end

    harness.truthy(danger.avoids(ctx, 1, destination, false),
        "low-HP rat accounts for poison's delayed damage")
end

return test
