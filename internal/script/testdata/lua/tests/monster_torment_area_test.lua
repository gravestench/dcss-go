-- A scroll and Symbol of Torment share one area owner. This test exercises
-- their entry points and LOS_NO_TRANS geometry while importing the live
-- schemas, catalog, resistance, and damage policies used by production.
local area = require("policy.combat.torment_area")
local component = require("constants.component")
local damage = require("policy.magic.damage")
local harness = require("tests.harness")
local channels = require("constants.message_channels")
local monsters = require("ids.monsters")
local player_health = require("policy.combat.player_health")
local player_resistance = require("policy.combat.player_resistance")
local scroll = require("policy.scrolls.effects.torment")
local senses = require("policy.character.senses")
local symbol = require("policy.combat.monster_spells.symbol_of_torment")
local targets = require("policy.ai.targets")
local target_kind = require("constants.target_kind")
local gods = require("constants.gods")

local test = {}
local caster = 101
local player = 202
local rat = 303
local blocked = 404
local distant = 505

local positions = {
    [caster] = { level_id = 1, x = 1, y = 1 },
    [player] = { level_id = 1, x = 2, y = 1 },
    [rat] = { level_id = 1, x = 3, y = 1 },
    [blocked] = { level_id = 1, x = 4, y = 1 },
    [distant] = { level_id = 1, x = 10, y = 1 },
}

-- Return live positions and HP for the area owner without copying a
-- component schema into this test. Stubs below isolate the health owners.
local function context()
    local state = {
        health = {
            [caster] = 100,
            [player] = 100,
            [rat] = 100,
            [blocked] = 100,
            [distant] = 100,
        },
        messages = {},
        allied = false,
    }
    local ctx = {}

    -- The player is a live entity in the same query as the monsters.
    function ctx:player()
        return player
    end

    -- Supply the production component IDs used by the area scan.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return positions[entity]
        end

        if id == component.HEALTH then
            return { current = state.health[entity] }
        end

        if id == component.RELIGION_WORSHIP and entity == player then
            return { god_id = gods.NO_GOD }
        end

        if id == component.ACTOR then
            return { kind_id = monsters.MONS_RAT }
        end

        return nil
    end

    -- A player component, rather than entity order, selects player rules.
    function ctx:has(entity, id)
        return id == component.PLAYER and entity == player
    end

    -- Include a blocked and an out-of-range actor to catch broad queries.
    function ctx:query()
        return { caster, player, rat, blocked, distant }
    end

    -- The wall before x=4 separates the blocked rat from the source.
    function ctx:visible_no_trans(_, _, _, _, x)
        return x < 4
    end

    -- Retain messages so both entry points can prove their channel.
    function ctx:emit(channel, message)
        state.messages[#state.messages + 1] = {
            channel = channel,
            text = message,
        }
    end

    return ctx, state
end

-- Replace only the downstream damage, perception, and allegiance services.
-- The production Torment area and monster effect remain under test.
local function install_services(state)
    local original = {
        player_vulnerable = player_resistance.torment,
        player_loss = player_resistance.torment_loss,
        player_damage = player_health.damage,
        monster_damage = damage.apply,
        sees_actor = senses.player_sees_actor,
        sees_cell = senses.player_sees_cell,
        allied = targets.allied,
        enemy = targets.enemy,
    }

    -- The separate player resistance owner has its own tests; this test
    -- supplies a positive loss to focus on routing and area geometry.
    player_resistance.torment = function()
        return false
    end

    -- Return a positive player HP loss without reproducing form logic.
    player_resistance.torment_loss = function(_, _, current)
        return math.floor(current / 2) - 1
    end

    -- Record player HP writes without requiring unrelated status services.
    player_health.damage = function(_, entity, amount)
        state.health[entity] = state.health[entity] - amount
    end

    -- Record monster HP writes; production Torment computes their amount.
    damage.apply = function(_, entity, amount)
        state.health[entity] = state.health[entity] - amount
    end

    -- The test does not model invisibility or the player's own vision.
    senses.player_sees_actor = function()
        return true
    end

    -- A visible test actor also has a visible cell.
    senses.player_sees_cell = function()
        return true
    end

    -- Flip this flag to check the source's allied-player avoidance rule.
    targets.allied = function()
        return state.allied
    end

    -- Any other live actor is an enemy for this focused prospect test.
    targets.enemy = function(_, source, entity)
        return source ~= entity
    end

    return original
end

-- Restore module methods because the production runtime caches Lua modules
-- across tests within one VM instance.
local function restore_services(original)
    player_resistance.torment = original.player_vulnerable
    player_resistance.torment_loss = original.player_loss
    player_health.damage = original.player_damage
    damage.apply = original.monster_damage
    senses.player_sees_actor = original.sees_actor
    senses.player_sees_cell = original.sees_cell
    targets.allied = original.allied
    targets.enemy = original.enemy
end

-- The same area harms its caster and vulnerable victims, but cannot pass a
-- wall or the seven-cell radius. An ally declines a harmful player cast.
function test.run()
    local ctx, state = context()
    local original = install_services(state)
    local plan = symbol.plan(ctx, caster, player)

    harness.equal(plan.kind, target_kind.ENTITY,
        "Symbol uses a saved self plan")
    harness.equal(plan.entity, caster,
        "Symbol retains its caster across intent resolution")

    symbol.resolve(ctx, caster, player, nil, plan)

    harness.truthy(state.health[caster] < 100,
        "the caster is in its own Torment radius")
    harness.truthy(state.health[player] < 100,
        "the player is tormented by the monster symbol")
    harness.truthy(state.health[rat] < 100,
        "a visible monster is tormented")
    harness.equal(state.health[blocked], 100,
        "LOS_NO_TRANS wall protects the blocked actor")
    harness.equal(state.health[distant], 100,
        "the area ends after seven cells")
    harness.equal(state.messages[1].channel, channels.SPELL,
        "monster symbol uses the spell channel")

    -- Source planning checks immunity even when nonlethal HP math would
    -- round a one-HP victim's actual damage down to zero.
    state.health[player] = 1
    state.health[rat] = 1
    harness.truthy(symbol.plan(ctx, caster, player),
        "susceptible one-HP foes still make Symbol worth casting")

    state.allied = true
    harness.falsy(symbol.plan(ctx, caster, player),
        "an ally avoids tormenting the player")

    local forged = {
        kind = target_kind.ENTITY,
        entity = rat,
    }
    local okay = pcall(symbol.resolve, ctx, caster, player, nil, forged)

    harness.falsy(okay, "forged Symbol source is rejected")

    local scroll_ctx, scroll_state = context()

    restore_services(original)
    original = install_services(scroll_state)
    scroll.apply(scroll_ctx, player, { known = false })

    harness.truthy(scroll_state.health[player] < 100,
        "the shared scroll rule still torments its reader")
    harness.equal(scroll_state.messages[1].channel, channels.READ,
        "the scroll keeps its read channel")

    restore_services(original)
end

return test
