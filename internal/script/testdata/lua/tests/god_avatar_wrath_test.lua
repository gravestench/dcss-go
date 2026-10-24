-- God spell wrath keeps source branch draws, feet targeting, and a distinct
-- transient attacker while using the ordinary monster beam contact rules.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local health = require("policy.combat.player_health")
local avatar = require("policy.religion.wrath.avatar")
local effects = require("policy.combat.monster_spells")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local species = require("ids.species")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local trog = require("policy.religion.wrath.trog")
local yredelemnul = require("policy.religion.wrath.yredelemnul")

local test = {}

-- The player has live defense and HP state for ordinary beam contact.
local function player_at(ctx, x, level)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, x, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, { level = level })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.COMBAT, { shield_blocks = 0 })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 15,
        intelligence = 10,
        dexterity = 10,
    })

    return player
end

-- Pin card branch rolls and use minimum monster-spell rolls for repeatable
-- contact. A draw outside the supplied source sequence fails the test.
local function with_draws(ctx, draws)
    local owner = setmetatable({}, { __index = ctx })
    local used = 0

    function owner:random(stream, bound)
        harness.truthy(bound > 0, "avatar spell RNG bound must be positive")

        if stream ~= streams.CARDS then
            return 0
        end

        used = used + 1
        local value = draws[used]

        harness.truthy(value ~= nil, "unexpected god wrath choice")
        harness.truthy(value >= 0 and value < bound,
            "god wrath choice exceeds source bound")

        return value
    end

    function owner:draws_used()
        return used
    end

    return owner
end

-- Observe the attacker's live identity at the existing player HP owner,
-- then let the real damage implementation apply reactions and health loss.
local function cast_and_source(ctx, owner, player, cast)
    local original = health.damage
    local seen = nil

    health.damage = function(world, target, amount, fatal, attacker, cause)
        local override = attacker and world:get(attacker,
            component.VAULT_ACTOR_OVERRIDES)

        seen = override and {
            entity = attacker,
            god_id = override.god_id,
            name = override.custom_name,
            hd = override.hit_dice,
        }

        return original(world, target, amount, fatal, attacker, cause)
    end

    local ok, result = pcall(cast, owner, player)

    health.damage = original
    harness.truthy(ok, tostring(result))
    harness.truthy(result)
    harness.truthy(seen, "feet targeted spell must contact the player")
    harness.falsy(ctx:has(seen.entity, component.ACTOR),
        "temporary god avatar must be destroyed after its spell")

    return seen
end

-- Trog's third direct-wrath branch fires an ordinary Fireball at the player
-- with no additional card draw after its two branch decisions.
local function trog_fireball(ctx)
    local player = player_at(ctx, 10, 12)
    local owner = with_draws(fixture.context(ctx, player), { 1, 0 })
    local source = cast_and_source(ctx, owner, player, trog.apply)

    harness.equal(source.god_id, gods.TROG)
    harness.equal(source.name, "the fiery rage of Trog")
    harness.equal(source.hd, 12)
    harness.equal(owner:draws_used(), 2)
    harness.truthy(ctx:get(player, component.HEALTH).current < 100)
end

-- Yredelemnul's non-servant half casts a draining bolt from the same cell
-- and leaves the caster absent after the source damage path completes.
local function yred_draining(ctx)
    local player = player_at(ctx, 30, 15)
    local owner = with_draws(fixture.context(ctx, player), { 1 })
    local source = cast_and_source(ctx, owner, player, yredelemnul.apply)

    harness.equal(source.god_id, gods.YREDELEMNUL)
    harness.equal(source.name, "the anger of Yredelemnul")
    harness.equal(source.hd, 15)
    harness.equal(owner:draws_used(), 1)
end

-- Even a resolver failure cannot leave the transient shadow alive in the
-- action. Persistent-source spells are rejected before creating that body.
local function failure_cleanup(ctx)
    local player = player_at(ctx, 50, 8)
    local owner = fixture.context(ctx, player)
    local old = effects.effect

    effects.effect = function()
        return {
            resolve = function()
                error("resolver probe")
            end,
        }
    end

    local ok, message = pcall(avatar.cast, owner, player,
        gods.TROG, spells.SPELL_FIREBALL)

    effects.effect = old
    harness.falsy(ok)
    harness.truthy(string.find(message, "resolver probe", 1, true))

    for _, entity in ipairs(ctx:query({ component.ACTOR })) do
        local actor = ctx:get(entity, component.ACTOR)

        harness.falsy(actor.kind_id == monsters.MONS_PLAYER_SHADOW,
            "failed avatar cast retained its shadow")
    end

    ok, message = pcall(avatar.cast, owner, player,
        gods.TROG, "SPELL_UNREGISTERED_TEST")
    harness.falsy(ok)

    for _, entity in ipairs(ctx:query({ component.ACTOR })) do
        local actor = ctx:get(entity, component.ACTOR)

        harness.falsy(actor.kind_id == monsters.MONS_PLAYER_SHADOW,
            "missing spell resolver retained its shadow")
    end

end

-- Sticky Flame keeps dealing damage after the cast. Its saved source must
-- remain a hostile god entity without occupying the player's grid cell.
local function lasting_flame_source(ctx)
    local player = player_at(ctx, 58, 12)
    local owner = fixture.context(ctx, player)
    local okay, result = pcall(avatar.cast, owner, player,
        gods.MAKHLEB, spells.SPELL_STICKY_FLAME)

    harness.truthy(okay, tostring(result))
    harness.truthy(result)

    local flame = ctx:get(player, component.STICKY_FLAME)

    harness.truthy(flame, "god spell did not apply Sticky Flame")
    harness.truthy(ctx:has(flame.source,
        component.RELIGION_AVATAR_SOURCE),
        "lasting flame lost its god source")
    harness.falsy(ctx:has(flame.source, component.POSITION),
        "god source must not occupy the map after casting")

    ctx:remove(player, component.STICKY_FLAME)
    avatar.cleanup(owner)
    harness.falsy(ctx:has(flame.source,
        component.RELIGION_AVATAR_SOURCE),
        "spent god source remained after its last effect")
end

-- Clouds, temporary terrain, and summons carry three different source
-- representations. Keep one inert god owner until every one has gone.
local function lasting_world_sources(ctx)
    local player = player_at(ctx, 65, 12)
    local owner = fixture.context(ctx, player)
    local original = effects.effect
    local dependents = {}

    effects.effect = function()
        return {
            resolve = function(world, caster)
                local cloud = world:create()
                local terrain_change = world:create()
                local summon = world:create()

                world:add(cloud, component.WORLD_CLOUD, {
                    source_actor_id = world:id(caster),
                })
                world:add(terrain_change, component.TEMPORARY_TERRAIN, {
                    source_actor_id = world:id(caster),
                })
                world:add(summon, component.SUMMON, {
                    owner = caster,
                })
                dependents = { cloud, terrain_change, summon }
            end,
        }
    end

    local okay, result = pcall(avatar.cast, owner, player,
        gods.MAKHLEB, spells.SPELL_FIREBALL)

    effects.effect = original
    harness.truthy(okay, tostring(result))

    local sources = ctx:query({ component.RELIGION_AVATAR_SOURCE })

    harness.equal(#sources, 1)
    harness.falsy(ctx:has(sources[1], component.POSITION))

    for _, dependent in ipairs(dependents) do
        ctx:destroy(dependent)
    end

    avatar.cleanup(owner)
    harness.equal(#ctx:query({ component.RELIGION_AVATAR_SOURCE }), 0)
end

-- Vehumet can conjure hostile ball lightning through the same shadow.
-- Its saved summons must keep a source owner after that shadow leaves.
local function lasting_ball_lightning(ctx)
    local player = player_at(ctx, 70, 15)
    local owner = fixture.context(ctx, player)
    local okay, result = pcall(avatar.cast, owner, player,
        gods.VEHUMET, spells.SPELL_CONJURE_BALL_LIGHTNING)

    harness.truthy(okay, tostring(result))
    harness.truthy(result)

    local sources = ctx:query({ component.RELIGION_AVATAR_SOURCE })

    harness.equal(#sources, 1)

    local balls = 0

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)

        if state.source_id == spells.SPELL_CONJURE_BALL_LIGHTNING then
            harness.equal(state.owner, sources[1])
            balls = balls + 1
        end
    end

    harness.truthy(balls > 0, "god spell placed no ball lightning")
end

-- Both independent casts use production Lua component schemas and effects.
function test.run(ctx)
    trog_fireball(ctx)
    yred_draining(ctx)
    failure_cleanup(ctx)
    lasting_flame_source(ctx)
    lasting_world_sources(ctx)
    lasting_ball_lightning(ctx)
end

return test
