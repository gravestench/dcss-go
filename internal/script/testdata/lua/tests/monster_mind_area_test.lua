-- Cause Fear and Mass Confusion share area selection but store different
-- victim statuses. This test calls their production effects and imports the
-- real component schema; only unavailable host combat services are fixed.
local component = require("constants.component")
local fear = require("policy.character.player_fear")
local cause_fear = require("policy.combat.monster_spells.cause_fear")
local confusion = require("policy.combat.monster_spells.mass_confusion")
local harness = require("tests.harness")
local hex = require("policy.combat.monster_spells.hex")
local monsters = require("ids.monsters")
local resistance = require("policy.combat.player_resistance")
local senses = require("policy.character.senses")
local species = require("ids.species")
local target_kind = require("constants.target_kind")

local test = {}
local caster = 101
local player = 202

-- The fixture stores only live ECS snapshots and geometry. Catalog rules,
-- actor allegiance, area selection, and both status owners remain real.
local function game_context()
    local data = {
        [caster] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_RAT,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 1,
                y = 1,
            },
            [component.HEALTH] = {
                current = 10,
                max = 10,
            },
        },
        [player] = {
            [component.ACTOR] = {},
            [component.PLAYER] = {
                species_id = species.SP_HUMAN,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 2,
                y = 1,
            },
            [component.HEALTH] = {
                current = 20,
                max = 20,
            },
        },
    }
    local messages = {}
    local ctx = {}

    -- A player and one hostile monster are enough to exercise the live
    -- area query without duplicating the production component schemas.
    function ctx:query(required)
        local result = {}

        for _, entity in ipairs({ caster, player }) do
            local matches = true

            for _, id in ipairs(required) do
                matches = matches and data[entity][id] ~= nil
            end

            if matches then
                result[#result + 1] = entity
            end
        end

        return result
    end

    -- The test represents the staged view that later callbacks see.
    function ctx:get(entity, id)
        return data[entity] and data[entity][id] or nil
    end

    function ctx:has(entity, id)
        return data[entity] ~= nil and data[entity][id] ~= nil
    end

    function ctx:add(entity, id, value)
        harness.falsy(self:has(entity, id), "component is new")
        data[entity][id] = value
    end

    function ctx:set(entity, id, value)
        harness.truthy(self:has(entity, id), "component exists")
        data[entity][id] = value
    end

    function ctx:remove(entity, id)
        data[entity][id] = nil
    end

    function ctx:player()
        return player
    end

    function ctx:visible_no_trans()
        return true
    end

    function ctx:visible()
        return true
    end

    function ctx:random(_, bound)
        harness.truthy(bound > 0, "draw has a positive bound")
        return 0
    end

    function ctx:emit(kind, message)
        messages[#messages + 1] = {
            kind = kind,
            message = message,
        }
    end

    return ctx, data, messages
end

-- The focused fixture holds the will result constant. Willpower and
-- resistance calculations have their own tests; this tests spell routing.
local function fixed_will()
    local original = {
        resisted = hex.resisted,
        clarity = resistance.clarity,
        sees = senses.player_sees_actor,
    }

    hex.resisted = function()
        return false
    end

    resistance.clarity = function()
        return false
    end

    senses.player_sees_actor = function()
        return true
    end

    return original
end

-- Restore the cached production modules so later Lua tests see the actual
-- will, clarity, and visibility policies.
local function restore(original)
    hex.resisted = original.resisted
    resistance.clarity = original.clarity
    senses.player_sees_actor = original.sees
end

-- Check the production schema and both spells' live player statuses. A
-- valid fearmonger blocks approach, then expires after sufficient aut.
function test.run(runtime_ctx)
    local entity = runtime_ctx:create()

    runtime_ctx:add(entity, component.PLAYER_FEAR, {})

    local defaults = runtime_ctx:get(entity, component.PLAYER_FEAR)
    harness.equal(defaults.remaining_aut, 0,
        "fear schema supplies its duration default")
    harness.equal(#defaults.sources, 0,
        "fear schema supplies an empty source list")

    local ctx, data = game_context()
    local original = fixed_will()
    data[player][component.POSITION].x = 20
    harness.falsy(cause_fear.plan(ctx, caster, player),
        "fear is not offered without an actor in sight")
    harness.falsy(confusion.plan(ctx, caster, player),
        "confusion is not offered without an actor in sight")
    data[player][component.POSITION].x = 2

    local fear_plan = cause_fear.plan(ctx, caster, player)

    harness.equal(fear_plan.kind, target_kind.ENTITY,
        "the area spell saves its caster target")
    cause_fear.resolve(ctx, caster, player, nil, fear_plan)
    harness.truthy(data[player][component.PLAYER_FEAR],
        "fear becomes saved player state")
    harness.equal(fear.blocked(ctx, player,
        data[player][component.POSITION], {
            level_id = 1,
            x = 1,
            y = 1,
        }), caster, "the player cannot step toward the fearmonger")

    local confusion_plan = confusion.plan(ctx, caster, player)
    harness.truthy(confusion_plan,
        "mass confusion has a player target")
    confusion.resolve(ctx, caster, player, nil, confusion_plan)
    harness.equal(data[player]["zap.player_confusion"].remaining_aut, 50,
        "mass confusion applies five turns after a failed save")

    resistance.clarity = function()
        return true
    end

    local clear_ctx, clear_data = game_context()
    local clear_plan = confusion.plan(clear_ctx, caster, player)

    confusion.resolve(clear_ctx, caster, player, nil, clear_plan)
    harness.falsy(clear_data[player]["zap.player_confusion"],
        "clarity rejects confusion after the will contest")

    fear.tick(ctx, player, 170)
    harness.falsy(data[player][component.PLAYER_FEAR],
        "fear expires on the player's elapsed aut")

    restore(original)
end

return test
