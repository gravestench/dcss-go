-- Cloud Mage ignores every cloud before elemental damage.

local harness = require("tests.harness")
local ids = require("ids.clouds")
local monsters = require("ids.monsters")
local component = require("constants.component")
local artefacts = require("ids.artefacts")

local test = {}

-- Exercise smoke, innate immunity, artefact immunity, and holy immunity in one exposure fixture.
function test.run()
    local exposure = require("policy.clouds.exposure")
    -- A smoke cloud can occupy a cell without damage or an emitted message.
    local emitted = 0
    local context = {}

    -- Count messages so harmless smoke cannot silently emit combat text.
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

    -- Swap in Cloud Mage identity before testing fire exposure immunity.
    function context:get(_, kind)
        if kind == component.ACTOR then
            return {
                kind_id = monsters.MONS_CLOUD_MAGE,
            }
        end
    end

    -- Cloud Mage immunity is checked before elemental fire damage.
    local fire = {
        kind_id = ids.CLOUD_FIRE,
        decay_aut = 20,
    }

    harness.equal(exposure.apply(context, 1, 2, fire, 10), 0,
        "Cloud Mage ignores every cloud before elemental damage")

    -- Replace the worn-item lookup to exercise the robe's all-cloud shield.
    local equipment = require("policy.combat.equipment")
    local original_worn = equipment.worn
    local robe = {}

    -- Make the artefact holder the target of the fire cloud.
    function robe:player()
        return 1
    end

    -- Identify only the worn Robe of Clouds artefact; the rest of inventory is irrelevant.
    function robe:get(entity, kind)
        if entity == 7 and kind == component.ITEM_ARTEFACT then
            return {
                unique_id = artefacts.UNRAND_RCLOUDS,
            }
        end
    end

    -- Replace inventory scanning with one equipped body slot to isolate artefact immunity.
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

    -- Holy cloud immunity uses monster holiness rather than worn equipment.
    local holy = require("policy.clouds.effects.holy")
    local angel = {}

    -- Keep the angel as a monster so holy immunity checks catalog holiness.
    function angel:player()
        return 99
    end

    -- Resolve the angel's monster definition through its actor component.
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
