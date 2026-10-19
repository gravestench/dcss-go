-- The production Mesmerise and Siren handlers share one saved beholder
-- owner. Avatar Song then reuses it while its own caster status keeps time.
-- The test imports production IDs and schemas; it fixes only host services
-- unavailable in this isolated Lua rule runner.
local avatar = require("policy.combat.monster_avatar_song")
local component = require("constants.component")
local harness = require("tests.harness")
local hex = require("policy.combat.monster_spells.hex")
local mesmerism = require("policy.character.player_mesmerism")
local mesmerise = require("policy.combat.monster_spells.mesmerise")
local monsters = require("ids.monsters")
local noise = require("policy.world.noise")
local pull = require("policy.combat.monster_avatar_song.pull")
local resistance = require("policy.combat.player_resistance")
local senses = require("policy.character.senses")
local siren = require("policy.combat.monster_spells.siren_song")
local souls = require("policy.combat.monster_avatar_song.souls")
local statuses = require("policy.magic.effects.statuses.player")
local target_kind = require("constants.target_kind")

local test = {}
local caster = 101
local player = 202

-- Keep only the mutable actor records and engine callbacks needed by the
-- production spell and status owners. Catalog and spellbook data stay real.
local function game_context(kind)
    local data = {
        [caster] = {
            [component.ACTOR] = {
                kind_id = kind,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 2,
                y = 2,
            },
            [component.HEALTH] = {
                current = 20,
                max = 20,
            },
        },
        [player] = {
            [component.PLAYER] = {},
            [component.POSITION] = {
                level_id = 1,
                x = 3,
                y = 2,
            },
            [component.HEALTH] = {
                current = 20,
                max = 20,
            },
        },
    }
    local state = {
        random = 1,
        messages = {},
    }
    local ctx = {}

    -- The player service identifies the victim, while target arguments
    -- still determine which actor a spell is allowed to affect.
    function ctx:player()
        return player
    end

    -- Tests observe the staged ECS view produced by the actual policies.
    function ctx:get(entity, id)
        return data[entity] and data[entity][id] or nil
    end

    -- Presence selects add versus set for the saved beholder owner.
    function ctx:has(entity, id)
        return data[entity] ~= nil and data[entity][id] ~= nil
    end

    -- Silence now reads all live aura sources. Match the host's component
    -- query contract instead of suppressing that production lookup.
    function ctx:query(required)
        local found = {}

        for _, entity in ipairs({ caster, player }) do
            local complete = true

            for _, id in ipairs(required) do
                complete = complete and self:has(entity, id)
            end

            if complete then
                found[#found + 1] = entity
            end
        end

        return found
    end

    -- A fresh status must not silently replace an existing component.
    function ctx:add(entity, id, value)
        harness.falsy(self:has(entity, id), "new status was absent")
        data[entity][id] = value
    end

    -- A refreshed status must replace a component already on the entity.
    function ctx:set(entity, id, value)
        harness.truthy(self:has(entity, id), "updated status existed")
        data[entity][id] = value
    end

    -- Breaking the final hold eventually removes the expired component.
    function ctx:remove(entity, id)
        data[entity][id] = nil
    end

    -- Unobstructed cells keep the fixture focused on beholder rules rather
    -- than duplicating the production terrain and visibility services.
    function ctx:visible()
        return true
    end

    -- Mutual solid sight holds unless an explicit status breaks the song.
    function ctx:visible_no_trans()
        return true
    end

    -- Avoid a second RNG implementation while checking spell decisions.
    function ctx:random(_, bound)
        harness.truthy(bound > 0, "random draw has positive bound")

        return math.min(state.random, bound - 1)
    end

    -- Keep notices available for future message-specific assertions.
    function ctx:emit(kind_id, message)
        state.messages[#state.messages + 1] = {
            kind = kind_id,
            text = message,
        }
    end

    return ctx, data, state
end

-- Fix will, hearing, sight, and the avatar's later movement/summons at
-- their host boundaries. The real spell plans and status transitions run.
local function fixed_services()
    local old = {
        resisted = hex.resisted,
        noise = noise.emit,
        clarity = resistance.clarity,
        sees = senses.player_sees_actor,
        cell = senses.player_sees_cell,
        silence = statuses.silence_radius,
        pull = pull.apply,
        souls = souls.apply,
    }
    local calls = {
        pull = 0,
        souls = 0,
    }

    -- A failed will contest reaches the production beholder owner.
    hex.resisted = function()
        return false
    end

    -- Hearing is granted so the source can sing in this isolated fixture.
    noise.emit = function()
        return 7, true
    end

    -- Clarity is independent of the spell and duration behavior under test.
    resistance.clarity = function()
        return false
    end

    -- Visible casters can begin a fresh direct or sung hold.
    senses.player_sees_actor = function()
        return true
    end

    -- Keep first-call avatar messaging independent of terrain rendering.
    senses.player_sees_cell = function()
        return true
    end

    -- With no Silence field, hearing decides whether a song is possible.
    statuses.silence_radius = function()
        return -1
    end

    -- Count the continuation's pull; the separate grid test checks movement.
    pull.apply = function()
        calls.pull = calls.pull + 1

        return true
    end

    -- Count the continuation's call; the grid test checks water placement.
    souls.apply = function(_, _, song)
        calls.souls = calls.souls + 1
        song.called = true
    end

    return old, calls
end

-- Cached policy modules must regain their production functions before the
-- next Lua test runs in the same runtime.
local function restore(old)
    hex.resisted = old.resisted
    noise.emit = old.noise
    resistance.clarity = old.clarity
    senses.player_sees_actor = old.sees
    senses.player_sees_cell = old.cell
    statuses.silence_radius = old.silence
    pull.apply = old.pull
    souls.apply = old.souls
end

-- Verify the registered schema, chosen target, blocked retreat, immunity,
-- Siren Song, and the avatar's caster-owned continuation in one slice.
function test.run(runtime_ctx)
    local entity = runtime_ctx:create()
    local source = runtime_ctx:create()

    runtime_ctx:add(entity, component.PLAYER_MESMERISM, {})

    local defaults = runtime_ctx:get(entity,
        component.PLAYER_MESMERISM)

    harness.equal(defaults.remaining_aut, 0,
        "mesmerism schema supplies a zero timer")
    harness.equal(defaults.immune_aut, 0,
        "mesmerism schema supplies zero immunity")
    harness.equal(#defaults.sources, 0,
        "mesmerism schema supplies an empty source list")

    defaults.sources = { source }
    runtime_ctx:set(entity, component.PLAYER_MESMERISM, defaults)

    local stored = runtime_ctx:get(entity, component.PLAYER_MESMERISM)

    harness.equal(stored.sources[1], source,
        "beholder references use live entity handles")

    local old, calls = fixed_services()
    local ctx, data = game_context(monsters.MONS_MAGGIE)
    local plan = mesmerise.plan(ctx, caster, player)

    harness.equal(plan.kind, target_kind.ENTITY,
        "direct mesmerism saves an entity target")
    harness.equal(plan.entity, player,
        "direct mesmerism keeps the selected player")
    mesmerise.resolve(ctx, caster, player, nil, plan)
    harness.truthy(mesmerism.beheld_by(ctx, player, caster),
        "failed will makes the caster a beholder")
    harness.equal(mesmerism.blocked(ctx, player,
        data[player][component.POSITION], {
            x = 4,
            y = 2,
        }), caster, "the beholder prevents a step away")

    data[caster][component.MONSTER_CONFUSION] = {
        remaining_aut = 10,
    }
    mesmerism.tick(ctx, player, 10)

    local recovered = data[player][component.PLAYER_MESMERISM]

    harness.equal(recovered.remaining_aut, 0,
        "an incapacitated source ends its hold")
    harness.truthy(recovered.immune_aut > 0,
        "breaking free starts saved immunity")
    data[caster][component.MONSTER_CONFUSION] = nil

    local siren_ctx, siren_data = game_context(
        monsters.MONS_MERFOLK_SIREN)
    local song_plan = siren.plan(siren_ctx, caster, player)

    harness.truthy(song_plan, "an audible siren may sing")
    siren.resolve(siren_ctx, caster, player, nil, song_plan)
    harness.truthy(siren_data[player][component.PLAYER_MESMERISM],
        "Siren Song uses the shared beholder state")

    local avatar_ctx, avatar_data, avatar_state = game_context(
        monsters.MONS_MERFOLK_AVATAR)

    mesmerism.apply(avatar_ctx, player, caster)
    avatar.start(avatar_ctx, caster, player)
    avatar_state.random = 0
    avatar.tick(avatar_ctx, caster, 10)
    harness.equal(calls.pull, 1,
        "one avatar pulse attempts one pull")
    harness.equal(calls.souls, 1,
        "one avatar pulse considers drowned souls")
    harness.truthy(avatar_data[caster][component.MONSTER_AVATAR_SONG],
        "the continuing song remains on its caster")

    avatar_data[caster][component.MONSTER_MUTE] = {}
    avatar.tick(avatar_ctx, caster, 10)
    harness.falsy(avatar_data[caster][component.MONSTER_AVATAR_SONG],
        "silence interrupts the avatar song")

    restore(old)
end

return test
