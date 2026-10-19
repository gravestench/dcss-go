
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

-- The intent carries a selected slot and target; execution must reuse both
-- without drawing or selecting a new target.
local function context(spell_id, spell_slot, planned_kind,
    construct_attitude)
    local ctx = {
        cast_signals = {},
    }

    -- Completed monster book casts publish a battlesphere trigger; construct
    -- abilities must never claim to be a fresh spellbook conjuration.
    function ctx:signal(name, entity)
        self.cast_signals[#self.cast_signals + 1] = {
            name = name,
            entity = entity,
        }
    end

    -- Bind execution to the selected player target in the saved plan.
    function ctx:player()
        return player
    end

    -- Keep optional statuses absent so slot validation is isolated.
    function ctx:has(entity, id)
        return construct_attitude and entity == caster and
            id == component.SUMMON
    end

    -- Return the exact caster intent and spellbook data used at the execution boundary.
    function ctx:get(entity, id)
        if entity == caster then
            if id == component.SUMMON and construct_attitude then
                return { attitude = construct_attitude }
            end

            if id == component.INTENT then
                return {
                    kind = intents.SPELL,
                    spell_id = spell_id,
                    spell_slot = spell_slot,
                    foe_entity = player,
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

-- Wrong slot cannot borrow another spell ID.
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

    -- Expose the test spellbook ID while preserving production lookup for every other book.
    register.get = function(category, id)
        if category == "monster_spellbooks" and id == source_book then
            return book
        end

        return original_get(category, id)
    end

    -- Inject an effect whose resolver records the saved entity plan.
    effects.effect = function()
        return {
            -- Fail if execution replans a target after intent selection.
            plan = function()
                error("execution must not choose a second target")
            end,

            -- Assert the selected player entity reaches the resolver unchanged.
            resolve = function(_, _, _, _, plan)
                harness.equal(plan.kind, target_kind.ENTITY,
                    "entity target reaches resolver")
                harness.equal(plan.entity, player,
                    "chosen foe reaches resolver")
                resolved = resolved + 1
            end,
        }
    end

    -- The source book has a second-slot Slug Dart; count exactly one resolver
    -- call for an entity plan and then one for a cell plan.
    local valid = context(spells.SPELL_SLUG_DART, 2)
    local okay, problem = pcall(system.update, valid, caster)

    harness.truthy(okay, "second slot executes: " .. tostring(problem))
    harness.equal(resolved, 1, "selected second effect resolves once")
    harness.equal(valid.cast_signals[1].name,
        "monster_spell_success",
        "a completed book cast signals reactive constructs")

    -- Inject a second effect to verify saved cell plans survive execution.
    effects.effect = function()
        return {
            -- Fail if execution asks the cell spell to plan again.
            plan = function()
                error("execution must not choose a cell target")
            end,

            -- Assert the selected level and coordinates reach the cell resolver unchanged.
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

    -- Matching the spell ID is insufficient if the chosen slot was forged.
    local forged = context(spells.SPELL_SLUG_DART, 1)

    okay = pcall(system.update, forged, caster)

    harness.falsy(okay, "wrong slot cannot borrow another spell ID")
    harness.equal(resolved, 2, "forged slot did not execute")

    -- Construct abilities reuse the spell-speed intent number but have no
    -- spellbook slot; their own system resolves them before this gate.
    local construct = context(spells.SPELL_FOXFIRE, 0, nil,
        "friendly")

    okay, problem = pcall(system.update, construct, caster)

    harness.truthy(okay,
        "construct ability stays with its owner: " .. tostring(problem))
    harness.equal(resolved, 2,
        "monster spellbook resolver does not run a construct ability")

    -- Marshlight produces hostile foxfire. Its allegiance cannot turn the
    -- same construct intent into a spellbook cast without a slot.
    local hostile = context(spells.SPELL_MARSHLIGHT, 0, nil,
        "hostile")

    okay, problem = pcall(system.update, hostile, caster)

    harness.truthy(okay,
        "hostile construct ability stays with its owner: " ..
            tostring(problem))
    harness.equal(resolved, 2,
        "hostile construct never reaches the spellbook resolver")
    harness.equal(#hostile.cast_signals, 0,
        "a hostile construct action emits no spell success signal")

    -- A Lua construct intent omits spell_slot entirely. The host does not
    -- synthesize a zero field when Lua reads that component back.
    local omitted = context(spells.SPELL_MARSHLIGHT, nil, nil,
        "hostile")

    okay, problem = pcall(system.update, omitted, caster)

    harness.truthy(okay,
        "omitted construct slot stays with its owner: " ..
            tostring(problem))
    harness.equal(resolved, 2,
        "an omitted slot is not treated as a monster spellbook cast")

    register.get = original_get
    effects.effect = original_effect
end

return test
