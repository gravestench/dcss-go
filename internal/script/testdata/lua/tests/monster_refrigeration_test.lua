-- Both player and monster Refrigeration now import the source adjacency
-- formula. This exercises the monster's real LOS policy and profile, with
-- only the grid, allegiance, and final health owner supplied by a fixture.
local area = require("policy.combat.monster_area.refrigeration")
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local effect = require("policy.combat.monster_spells.ozocubus_refrigeration")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local test = {}
local caster = 11
local foe = 22
local second = 33

-- The two nearby victims make collateral scoring and one-body damage
-- dilution observable without copying the production monster definitions.
local function context()
    local state = {
        [caster] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_ANGEL,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 2,
                y = 2,
            },
            [component.HEALTH] = {
                current = 40,
            },
        },
        [foe] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_RAT,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 4,
                y = 2,
            },
            [component.HEALTH] = {
                current = 20,
            },
        },
        [second] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_GOBLIN,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 3,
                y = 2,
            },
            [component.HEALTH] = {
                current = 20,
            },
        },
    }
    local ctx = {}

    -- Production area and resistance owners read the same live components.
    function ctx:get(entity, id)
        return state[entity] and state[entity][id]
    end

    -- This isolated cast has no player target or player-owned component.
    function ctx:has(entity, id)
        return state[entity] and state[entity][id] ~= nil or false
    end

    -- Source adjacency sees the caster as well as both living victims.
    function ctx:query(required)
        for _, id in ipairs(required or {}) do
            if id == component.EQUIPPED or
                id == component.CARRIED_BY then
                return {}
            end
        end

        return { caster, foe, second }
    end

    -- No player has been created in this monster-on-monster fixture.
    function ctx:player()
        return nil
    end

    -- Walls do not split this source LOS_NO_TRANS attack.
    function ctx:visible_no_trans()
        return true
    end

    -- Choose minimum damage to make the four-die floor explicit.
    function ctx:random(_, bound)
        harness.truthy(bound > 0, "a cold roll has a positive bound")

        return 0
    end

    -- Hidden-caster messages are irrelevant to damage and target choice.
    function ctx:emit()
    end

    return ctx, state
end

-- Restore cached policy functions so later Lua tests retain production
-- allegiance, visibility, armour, and health behavior.
local function restore(old)
    targets.enemy = old.enemy
    targets.allied = old.allied
    senses.player_sees_actor = old.sees_actor
    senses.player_sees_cell = old.sees_cell
    direct.armour = old.armour
    direct.damage = old.damage
end

-- Test collateral refusal, shared adjacency, the monster zap dice floor,
-- and source-attributed damage to both enemies after a safe plan.
function test.run()
    local old = {
        enemy = targets.enemy,
        allied = targets.allied,
        sees_actor = senses.player_sees_actor,
        sees_cell = senses.player_sees_cell,
        armour = direct.armour,
        damage = direct.damage,
    }
    local second_is_enemy = false
    local hits = {}

    -- Make the goblin first an ally and then an enemy of the angel caster.
    targets.enemy = function(_, _, victim)
        return victim == foe or
            victim == second and second_is_enemy
    end

    -- This caster is hostile; source's friendly-player veto does not apply.
    targets.allied = function()
        return false
    end

    -- An offscreen cast must still change world state without narration.
    senses.player_sees_actor = function()
        return false
    end

    -- The source cell is outside the player's current view.
    senses.player_sees_cell = function()
        return false
    end

    -- Isolate the cold dice from the separate armour implementation.
    direct.armour = function(_, _, raw)
        return raw
    end

    -- Apply the production spell's chosen HP losses to this fixture.
    direct.damage = function(ctx, _, victim, amount)
        local health = ctx:get(victim, component.HEALTH)

        health.current = health.current - amount
        hits[#hits + 1] = {
            victim = victim,
            amount = amount,
        }
    end

    local ctx = context()

    harness.falsy(effect.plan(ctx, caster),
        "one equal ally and enemy fails the source foe ratio")
    second_is_enemy = true

    local plan = effect.plan(ctx, caster)

    harness.truthy(plan,
        "two vulnerable enemies make the LOS cast worthwhile")

    local snapshot = area.snapshot(ctx, caster)

    harness.equal(area.adjacent(snapshot, foe), 1,
        "the nearby goblin dilutes the rat's cold dice")
    effect.resolve(ctx, caster, foe, nil, plan)
    harness.equal(#hits, 2,
        "the source area attack reaches both living victims")
    harness.equal(hits[1].amount, 4,
        "minimum four-die cold damage has a floor of four")

    -- A separate deterministic draw distinguishes one-body dilution from
    -- the undiluted case without invoking unrelated combat services.
    local maximum = {
        random = function(_, _, bound)
            return bound - 1
        end,
    }
    local diluted = area.raw_damage(maximum, 9, 1,
        streams.MONSTER_SPELL)
    local plain = area.raw_damage(maximum, 9, 0,
        streams.MONSTER_SPELL)

    harness.truthy(diluted < plain,
        "one adjacent nonconjured body reduces the die size")

    restore(old)
end

return test
