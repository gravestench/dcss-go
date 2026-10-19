local component = require("constants.component")
local harness = require("tests.harness")
local status = require("policy.combat.monster_hexes.status")

local test = {}

function test.run()
    local actor = 101
    local values = {}
    local ctx = {}

    function ctx:get(entity, id)
        return values[entity] and values[entity][id]
    end

    function ctx:add(entity, id, value)
        values[entity] = values[entity] or {}
        values[entity][id] = value
    end

    function ctx:set(entity, id, value)
        values[entity][id] = value
    end

    function ctx:remove(entity, id)
        values[entity][id] = nil
    end

    status.corona(ctx, actor, 30)
    status.anchor(ctx, actor, 50)
    status.poison_vulnerability(ctx, actor, 20)
    status.sap_magic(ctx, actor, 40)

    harness.truthy(status.anchored(ctx, actor),
        "anchor is active in saved actor state")
    harness.truthy(status.backlit(ctx, actor),
        "Corona is active in saved actor state")
    harness.truthy(status.poison_vulnerable(ctx, actor),
        "Virulence is active in saved actor state")
    harness.truthy(status.sapped(ctx, actor),
        "Sap Magic is active in saved actor state")

    status.tick(ctx, actor, 50)

    harness.falsy(ctx:get(actor, component.HEX_STATUS),
        "expired hex durations leave no dormant saved component")
end

return test
