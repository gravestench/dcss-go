-- Monster Irradiate shares the player spell's radiation rule. This fixture
-- keeps its real catalog and status policy while replacing the external
-- grid, armour, HP, and presentation services needed for a small scene.
local area = require("policy.combat.monster_area.irradiate")
local component = require("constants.component")
local defense = require("policy.combat.monster_defense")
local direct = require("policy.combat.monster_direct")
local effect = require("policy.combat.monster_spells.irradiate")
local harness = require("tests.harness")
local magic_damage = require("policy.magic.damage")
local monsters = require("ids.monsters")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local zap_ids = require("policy.magic.effects.zaps.ids")

local test = {}
local caster = 11
local player = 22
local ally = 33
local conjured = 44

-- The player, an ordinary monster, and a conjured vortex occupy three of
-- the caster's eight neighboring cells.
local function context()
    local state = {
        [caster] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_RAT,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 2,
                y = 2,
            },
            [component.HEALTH] = {
                current = 30,
            },
        },

        [player] = {
            [component.PLAYER] = {},
            [component.PROGRESSION] = {
                level = 27,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 3,
                y = 2,
            },
            [component.HEALTH] = {
                current = 30,
            },
        },

        [ally] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_GOBLIN,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 1,
                y = 2,
            },
            [component.HEALTH] = {
                current = 30,
            },
        },

        [conjured] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_FIRE_VORTEX,
                speed = 15,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 2,
                y = 3,
            },
            [component.HEALTH] = {
                current = 30,
            },
        },
    }
    local ctx = {}
    local draws = {}
    local events = {}

    -- Component reads return the fixture's current actor state.
    function ctx:get(entity, id)
        return state[entity] and state[entity][id]
    end

    -- Presence distinguishes a player victim from ordinary monsters.
    function ctx:has(entity, id)
        return state[entity] and state[entity][id] ~= nil or false
    end

    -- Wretched and contamination use their production schema IDs.
    function ctx:add(entity, id, value)
        state[entity][id] = value
    end

    -- Extend an existing status without losing its other saved fields.
    function ctx:set(entity, id, value)
        state[entity][id] = value
    end

    -- Source adjacency examines occupants regardless of floor walkability.
    function ctx:actor_at(level_id, x, y)
        local entities = {
            caster,
            player,
            ally,
            conjured,
        }

        for _, entity in ipairs(entities) do
            local position = state[entity][component.POSITION]

            if position and position.level_id == level_id and
                position.x == x and position.y == y then
                return entity
            end
        end

        return nil
    end

    -- All spell draws stay in the saved monster-spell stream.
    function ctx:random(stream, bound)
        harness.equal(stream, streams.MONSTER_SPELL,
            "monster radiation draws from the monster spell stream")
        harness.truthy(bound > 0,
            "every radiation draw has a positive bound")
        draws[#draws + 1] = bound

        return 0
    end

    -- The source distinguishes an adjacent player from other actors.
    function ctx:player()
        return player
    end

    -- Presentation is observed without changing the status outcome.
    function ctx:emit(channel, message)
        events[#events + 1] = {
            channel = channel,
            message = message,
        }
    end

    return ctx, state, draws, events
end

-- Test the real area rule and monster entry point with a surviving player,
-- a mutable ally, and an immune conjured body.
function test.run()
    local old = {
        enemy = targets.enemy,
        allied = targets.allied,
        sees = senses.player_sees_actor,
        armour = magic_damage.player_armour,
        monster_ac = defense.armour,
        damage = direct.damage,
    }
    local hits = {}

    targets.enemy = function(_, _, victim)
        return victim == player
    end

    targets.allied = function()
        return false
    end

    senses.player_sees_actor = function()
        return false
    end

    magic_damage.player_armour = function(_, _, raw)
        return raw
    end

    defense.armour = function()
        return 0
    end

    local ctx, state, draws = context()

    direct.damage = function(_, source, victim, amount)
        harness.equal(source, caster,
            "radiation damage retains the monster caster credit")
        hits[#hits + 1] = victim
        state[victim][component.HEALTH].current =
            state[victim][component.HEALTH].current - amount
    end

    area.resolve(ctx, caster, 6, streams.MONSTER_SPELL)
    harness.equal(#hits, 2,
        "radiation hits the player and ordinary monster")
    harness.equal(state[conjured][component.HEALTH].current, 30,
        "a conjured vortex ignores radiation")
    harness.equal(state[player][zap_ids.component.CONTAMINATION].amount,
        2000, "a surviving player gains hit contamination")
    harness.truthy(state[ally][zap_ids.component.WRETCHED],
        "a surviving ordinary monster gains saved Wretched status")
    harness.falsy(state[caster][zap_ids.component.CONTAMINATION],
        "a monster caster does not gain player self-contamination")
    harness.truthy(#draws > 0,
        "radiation rolls damage and consequences during resolution")

    state[ally][component.POSITION] = nil
    state[conjured][component.POSITION] = nil

    local plan = effect.plan(ctx, caster, player)

    harness.truthy(plan,
        "the monster AI may cast when only its hostile player is adjacent")

    local before = state[player][zap_ids.component.CONTAMINATION].amount

    effect.resolve(ctx, caster, player, nil, plan)
    harness.truthy(
        state[player][zap_ids.component.CONTAMINATION].amount > before,
        "the monster spell entry point applies player radiation")

    targets.enemy = old.enemy
    targets.allied = old.allied
    senses.player_sees_actor = old.sees
    magic_damage.player_armour = old.armour
    defense.armour = old.monster_ac
    direct.damage = old.damage
end

return test
