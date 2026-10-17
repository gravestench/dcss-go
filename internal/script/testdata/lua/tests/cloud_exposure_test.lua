local harness = require("tests.harness")
local ids = require("ids.clouds")
local monsters = require("ids.monsters")
local component = require("constants.component")
local artefacts = require("ids.artefacts")

local test = {}

function test.run()
    local exposure = require("policy.clouds.exposure")
    local emitted = 0
    local context = {}

    function context:emit()
        emitted = emitted + 1
    end

    local smoke = {
        kind_id = ids.CLOUD_GREY_SMOKE,
        decay_aut = 20,
    }

    local amount = exposure.apply(context, 1, 2, smoke, 10)

    harness.equal(amount, 0, "smoke has no direct damage")
    harness.equal(emitted, 0, "smoke has no exposure message")

    function context:get(_, kind)
        if kind == component.ACTOR then
            return {
                kind_id = monsters.MONS_CLOUD_MAGE,
            }
        end
    end

    local fire = {
        kind_id = ids.CLOUD_FIRE,
        decay_aut = 20,
    }

    harness.equal(exposure.apply(context, 1, 2, fire, 10), 0,
        "Cloud Mage ignores every cloud before elemental damage")

    local equipment = require("policy.combat.equipment")
    local original_worn = equipment.worn
    local robe = {}

    function robe:player()
        return 1
    end

    function robe:get(entity, kind)
        if entity == 7 and kind == component.ITEM_ARTEFACT then
            return {
                unique_id = artefacts.UNRAND_RCLOUDS,
            }
        end
    end

    equipment.worn = function()
        return {
            body = {
                entity = 7,
            },
        }
    end

    harness.equal(exposure.apply(robe, 1, 2, fire, 10), 0,
        "robe of Clouds grants all-cloud immunity")

    equipment.worn = original_worn

    local holy = require("policy.clouds.effects.holy")
    local angel = {}

    function angel:player()
        return 99
    end

    function angel:get(_, kind)
        if kind == component.ACTOR then
            return {
                kind_id = monsters.MONS_ANGEL,
            }
        end
    end

    harness.truthy(holy.immune(angel, 1),
        "holy monsters resist holy clouds")
end

return test
