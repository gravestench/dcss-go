
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local gear = require("policy.population.gear")
local goblin = require("policy.population.gear.handlers.goblin")
local harness = require("tests.harness")
local items = require("ids.items")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local test = {}

-- Choose the second gear outcome at the twelve-way goblin draw while other draws stay zero.
local function fake_random(_, _, bound)
    if bound == 12 then
        return 1
    end

    return 0
end

-- Dispatch registration rejects a second owner and an unknown monster key.
local function registry_rejects_duplicate_handlers()
    local added_id = monsters.MONS_RAT
    -- Register a harmless handler twice to isolate duplicate-ID rejection.
    local handler = function()
        return nil
    end

    registry.register(added_id, handler)

    local valid, reason = pcall(registry.register, added_id, handler)

    harness.falsy(valid, "duplicate gear handler was accepted")
    harness.truthy(reason:find("duplicate", 1, true),
        "duplicate handler error does not name rule")

    valid, reason = pcall(registry.register,
        monsters.MONS_RAT .. "_MISSING", handler)
    harness.falsy(valid, "unknown monster handler was accepted")
    harness.truthy(reason:find("unknown monster", 1, true),
        "missing monster error does not name rule")
    harness.falsy(gear.loadout(nil, monsters.MONS_RAT, 1),
        "unhandled monster received equipment")
end

-- The Goblin handler reads its catalog gear spec instead of an embedded roll.
local function goblin_reads_its_owned_spec()
    local definition = catalog.get(categories.MONSTERS, monsters.MONS_GOBLIN)
    local spec = definition.weapon_gear.primary
    local original_get = catalog.get
    local ctx = {
        random = fake_random,
    }

    spec.weapons = {
        {
            id = items.WPN_CLUB,
            weight = 1,
        },
    }

    -- Return the altered goblin gear row only for Goblin, preserving all other catalog lookups.
    catalog.get = function(category, id)
        if category == categories.MONSTERS and id == monsters.MONS_GOBLIN then
            return definition
        end

        return original_get(category, id)
    end

    local valid, loadout = pcall(goblin.loadout, ctx, 1)
    catalog.get = original_get

    harness.truthy(valid, "Goblin handler failed while using owned spec")

    harness.equal(loadout.primary.kind_id, items.WPN_CLUB,
        "Goblin handler ignored the owned weapon spec")
end

-- Gear handler failures identify the bad rule and the missing monster in error text.
function test.run()
    registry_rejects_duplicate_handlers()
    goblin_reads_its_owned_spec()
end

return test
