-- Command preparation checks ownership and charges before committing time.
local component = require("constants.component")
local evokers = require("policy.inventory.evokers")
local harness = require("tests.harness")
local ids = require("ids.items")
local intent = require("constants.intent")

local test = {}

-- Use the production charge owner with a minimal inventory context; effect
-- behavior has its own tests and does not need to be redeclared here.
function test.run()
    local player = {}
    local item_entity = {}
    local debt = 0
    local carried = true
    local confused = false
    local ctx = {}

    function ctx:entity(id)
        return id == 19 and item_entity or nil
    end

    function ctx:has()
        return false
    end

    function ctx:query()
        return {}
    end

    function ctx:get(entity, id)
        if entity == player and id == component.XP_EVOKERS then
            return { debt = { [ids.MISC_HORN_OF_GERYON] = debt } }
        end

        if entity == player and id == "zap.player_confusion" and confused then
            return { remaining_aut = 10 }
        end

        if entity == item_entity and id == component.ITEM then
            return { kind_id = ids.MISC_HORN_OF_GERYON }
        end

        if entity == item_entity and id == component.CARRIED_BY and carried then
            return { holder = player }
        end
    end

    local prepared = evokers.prepare(ctx, player, 19, 0, 0)

    harness.equal(prepared.intent.kind, intent.EVOKE_ITEM)
    harness.equal(prepared.cost, 10)

    debt = 10
    local empty = evokers.prepare(ctx, player, 19, 0, 0)

    harness.truthy(empty.message)
    harness.equal(empty.intent, nil)

    debt = 0
    carried = false
    local absent = evokers.prepare(ctx, player, 19, 0, 0)

    harness.truthy(absent.message)
    harness.equal(absent.intent, nil)

    carried = true
    confused = true
    local muddled = evokers.prepare(ctx, player, 19, 0, 0)

    harness.truthy(muddled.message)
    harness.equal(muddled.intent, nil)
end

return test
