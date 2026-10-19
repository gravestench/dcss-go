-- Ensnare is a damage flavour with a web side effect after beam contact.
-- It does not use the trap's pass-through roll: a direct magical web sticks.
local catalog = require("policy.catalog")
local component = require("constants.component")
local ensnare = require("policy.combat.monster_area.web")
local harness = require("tests.harness")
local held = require("policy.traps.held")
local placement = require("policy.traps.placement")
local size = require("constants.size")

local test = {}
local monster = 11
local giant = 22

-- A normal monster gets held and creates one temporary web; a giant actor
-- and a previously held actor are unaffected by the new web.
function test.run()
    local old_catalog = catalog.get
    local old_catch = held.catch_web
    local old_web = placement.temporary_web
    local observed = {
        held = 0,
        webs = 0,
    }
    local ctx = {}

    -- The giant starts held, so neither status nor placement may repeat.
    function ctx:has(target, id)
        return target == giant and id == component.TRAP_HELD
    end

    -- Actor identity and cell position are the only ECS reads Ensnare needs.
    function ctx:get(target, id)
        if id == component.HEALTH then
            if target == 44 then
                return nil
            end

            return { current = 10 }
        end

        if id == component.ACTOR then
            return {
                kind_id = target,
            }
        end

        if id == component.POSITION then
            return {
                level_id = 1,
                x = 4,
                y = 5,
            }
        end
    end

    -- Ordinary floor permits the source disposable web trap.
    function ctx:cell()
        return "DNGN_FLOOR"
    end

    -- Visible messages do not affect this restraint ownership assertion.
    function ctx:emit()
    end

    catalog.get = function(_, id)
        return {
            name = "test monster",
            size_id = id == giant and size.GIANT or size.MEDIUM,
            flags = {},
        }
    end

    held.catch_web = function()
        observed.held = observed.held + 1

        return true
    end

    placement.temporary_web = function()
        observed.webs = observed.webs + 1
    end

    ensnare.after_hit(ctx, nil, monster)
    ensnare.after_hit(ctx, nil, giant)
    ensnare.after_hit(ctx, nil, 44)

    harness.equal(observed.held, 1,
        "only a living eligible actor receives a web hold")
    harness.equal(observed.webs, 1,
        "an eligible floor contact gets a temporary web")

    catalog.get = old_catalog
    held.catch_web = old_catch
    placement.temporary_web = old_web
end

return test
