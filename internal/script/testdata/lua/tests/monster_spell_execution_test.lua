local catalog = require("policy.catalog")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local intents = require("constants.intent")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local system = require("systems.attack_spell")
local target_kind = require("constants.target_kind")

local test = {}

local caster = 101
local player = 202
local source_book = "MST_ENDOPLASM"

local function context(spell_id, spell_slot, planned_kind)
    local ctx = {}

    function ctx:player()
        return player
    end

    function ctx:has()
        return false
    end

    function ctx:get(entity, id)
        if entity == caster then
            if id == component.INTENT then
                return {
                    kind = intents.SPELL,
                    spell_id = spell_id,
                    spell_slot = spell_slot,
                    target_kind = planned_kind or target_kind.ENTITY,
                    target_entity = player,
                    target_level_id = 1,
                    target_x = 8,
                    target_y = 5,
                }
            end

            if id == component.ACTOR then
                return { kind_id = monsters.MONS_ENDOPLASM }
            end
        end

        if id == component.POSITION then
            return { level_id = 1, x = entity == caster and 5 or 6, y = 5 }
        end

        if id == component.HEALTH then
            return { current = 10, max = 10 }
        end

        return nil
    end

    return ctx
end

function test.run()
    local book = catalog.get("monster_spellbooks", source_book)
    local original_get = register.get
    local original_effect = effects.effect
    local resolved = 0

    book.slots = {
        {
            spell_id = spells.SPELL_FREEZE,
            frequency = 9,
            flags = {},
        },

        {
            spell_id = spells.SPELL_SLUG_DART,
            frequency = 18,
            flags = {},
        },
    }

    register.get = function(category, id)
        if category == "monster_spellbooks" and id == source_book then
            return book
        end

        return original_get(category, id)
    end

    effects.effect = function()
        return {
            plan = function()
                error("execution must not choose a second target")
            end,

            resolve = function(_, _, _, _, plan)
                harness.equal(plan.kind, target_kind.ENTITY,
                    "entity target reaches resolver")
                harness.equal(plan.entity, player,
                    "chosen foe reaches resolver")
                resolved = resolved + 1
            end,
        }
    end

    local valid = context(spells.SPELL_SLUG_DART, 2)
    local okay, problem = pcall(system.update, valid, caster)

    harness.truthy(okay, "second slot executes: " .. tostring(problem))
    harness.equal(resolved, 1, "selected second effect resolves once")

    effects.effect = function()
        return {
            plan = function()
                error("execution must not choose a cell target")
            end,

            resolve = function(_, _, _, _, plan)
                harness.equal(plan.kind, target_kind.CELL,
                    "empty-cell plan reaches resolver")
                harness.equal(plan.level_id, 1,
                    "cell target retains its level")
                harness.equal(plan.x, 8, "cell target retains its x")
                harness.equal(plan.y, 5, "cell target retains its y")
                resolved = resolved + 1
            end,
        }
    end

    local cell = context(spells.SPELL_SLUG_DART, 2, target_kind.CELL)

    okay, problem = pcall(system.update, cell, caster)

    harness.truthy(okay, "cell plan executes: " .. tostring(problem))
    harness.equal(resolved, 2, "selected cell effect resolves once")

    local forged = context(spells.SPELL_SLUG_DART, 1)

    okay = pcall(system.update, forged, caster)

    harness.falsy(okay, "wrong slot cannot borrow another spell ID")
    harness.equal(resolved, 2, "forged slot did not execute")

    register.get = original_get
    effects.effect = original_effect
end

return test
