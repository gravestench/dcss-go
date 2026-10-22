-- A heavy surviving hit from a real monster should trigger Jiyva's
-- five-star defence through the production player-health callback.
local causes = require("constants.damage_causes")
local categories = require("constants.catalog")
local component = require("constants.component")
local attitudes = require("constants.attitude")
local gods = require("constants.gods")
local harness = require("tests.harness")
local fixture = require("tests.monster_ally_support_fixture")
local monsters = require("ids.monsters")
local player_health = require("policy.combat.player_health")
local save_summons = require("policy.save.summons")
local streams = require("constants.rng_streams")

local test = {}

-- Capture the real policy's emitted text without depending on event order
-- from unrelated damage reactions in the same health call.
local function contains_message(messages, phrase)
    for _, message in ipairs(messages) do
        if message:find(phrase, 1, true) then
            return true
        end
    end

    return false
end

-- Count real ECS summons owned by this player rather than trusting a
-- message or replacing the production summon policy with a fake.
local function jiyva_summons(ctx, player)
    local found = {}

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local summon = ctx:get(entity, component.SUMMON)

        if summon.owner == player and summon.source_id == gods.JIYVA then
            found[#found + 1] = entity
        end
    end

    return found
end

-- Keep cases far apart on the fixture grid so earlier summoned bodies do
-- not block a later case. All actors still use production ECS schemas.
local function case_at(ctx, x, god_id, piety)
    local player = ctx:create()
    local game = fixture.context(ctx, player)
    local attacker = fixture.actor(ctx, monsters.MONS_GOBLIN,
        x, 5, 30)

    ctx:add(player, component.PLAYER, {})
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = x,
        y = 7,
    })
    ctx:add(player, component.HEALTH, {
        current = 100,
        max = 100,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = god_id,
        piety = piety,
    })

    -- A zero draw chooses the first species and the smallest count.
    function game:random(_, bound)
        return 0
    end

    return game, player, attacker
end

-- The first threshold is one quarter of maximum HP. A 25-point blow at
-- 100 maximum HP creates one ordinary summon with saved source metadata.
local function first_threshold(ctx)
    local game, player, attacker = case_at(ctx, 7, gods.JIYVA, 120)
    local draws = {}
    local messages = {}
    local original_random = game.random

    -- Record the production stream choices while retaining zero draws.
    function game:random(stream, bound)
        draws[#draws + 1] = {
            stream = stream,
            bound = bound,
        }

        return original_random(self, stream, bound)
    end

    -- Keep the source-facing message visible to this rule test.
    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    player_health.damage(game, player, 25, false,
        attacker, causes.HIT)

    local spawned = jiyva_summons(ctx, player)

    harness.equal(#spawned, 1)
    harness.equal(ctx:get(spawned[1], component.ACTOR).kind_id,
        monsters.MONS_ACID_BLOB)

    local state = ctx:get(spawned[1], component.SUMMON)

    harness.equal(state.owner, player)
    harness.equal(state.source_category, categories.GODS)
    harness.equal(state.attitude, attitudes.FRIENDLY)
    harness.equal(state.expires_aut, 180)

    local focus = ctx:get(spawned[1], component.SUMMON_HAUNTING)

    harness.equal(focus.target, attacker)

    -- Restoring this actor must accept both its god origin and its
    -- initial target; the ordinary save validator owns both checks.
    local saved_ai = ctx:get(spawned[1], component.AI)

    -- The Lua fixture omits schema zeroes; a Go save round trip restores
    -- these integer fields as zero before the validator reads them.
    saved_ai.target_x = saved_ai.target_x or 0
    saved_ai.target_y = saved_ai.target_y or 0
    saved_ai.memory_until_aut = saved_ai.memory_until_aut or 0

    save_summons.validate(game, spawned[1],
        ctx:get(spawned[1], component.ACTOR),
        ctx:get(spawned[1], component.POSITION),
        saved_ai, state, game:aut())

    local religion_placement = false

    for _, draw in ipairs(draws) do
        if draw.stream == streams.RELIGION and draw.bound == 8 then
            religion_placement = true
        end
    end

    harness.truthy(religion_placement,
        "Jiyva placement used the saved religion stream")
    harness.truthy(contains_message(messages,
        "shudder from the blow and a jelly pops out"))
end

-- The source compares final HP loss with integer fractions of max HP.
-- Random maximum rolls make the half and three-quarter tiers distinct.
local function higher_thresholds(ctx)
    local expectations = {
        { x = 25, damage = 24, count = 0 },
        { x = 43, damage = 50, count = 3 },
        { x = 61, damage = 75, count = 5 },
    }

    for _, expected in ipairs(expectations) do
        local game, player, attacker = case_at(ctx, expected.x,
            gods.JIYVA, 160)

        -- Maximum draws distinguish the two higher count tiers.
        function game:random(_, bound)
            return bound - 1
        end

        local messages = {}

        -- Observe the chosen impact wording alongside the real summons.
        function game:emit(_, message)
            messages[#messages + 1] = message
        end

        local cause = expected.damage == 50 and
            causes.BLAST or causes.HIT

        player_health.damage(game, player, expected.damage,
            false, attacker, cause)

        local spawned = jiyva_summons(ctx, player)

        harness.equal(#spawned, expected.count)

        for _, entity in ipairs(spawned) do
            harness.equal(ctx:get(entity, component.ACTOR).kind_id,
                monsters.MONS_QUICKSILVER_OOZE)
        end

        if expected.damage == 50 then
            harness.truthy(contains_message(messages,
                "shudder from the blast and a flood of jellies"))
        end
    end
end

-- No copied passive may survive penance or desertion; missing monster
-- provenance, self-harm, and a lethal blow also must not eject slimes.
local function ineligible_hits(ctx)
    local cases = {
        { x = 79, god = gods.JIYVA, piety = 119 },
        { x = 97, god = gods.NO_GOD, piety = 160 },
    }

    for _, entry in ipairs(cases) do
        local game, player, attacker = case_at(ctx, entry.x,
            entry.god, entry.piety)

        player_health.damage(game, player, 50, false,
            attacker, causes.HIT)

        harness.equal(#jiyva_summons(ctx, player), 0)
    end

    local game, player, attacker = case_at(ctx, 115,
        gods.JIYVA, 160)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.penance[gods.JIYVA] = 1
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    player_health.damage(game, player, 50, false,
        attacker, causes.HIT)

    harness.equal(#jiyva_summons(ctx, player), 0)

    local no_source, alone = case_at(ctx, 133,
        gods.JIYVA, 160)

    player_health.damage(no_source, alone, 50, false,
        nil, causes.ACID)

    harness.equal(#jiyva_summons(ctx, alone), 0)

    local lethal, victim, killer = case_at(ctx, 151,
        gods.JIYVA, 160)

    player_health.damage(lethal, victim, 100, false,
        killer, causes.HIT)

    harness.equal(#jiyva_summons(ctx, victim), 0)
end

-- A passive has no spell-failure message when every neighboring cell is
-- blocked. The hit still lands, but failed placement creates no actor.
local function blocked_ejection(ctx)
    local game, player, attacker = case_at(ctx, 169,
        gods.JIYVA, 160)
    local messages = {}

    for y = 6, 8 do
        for x = 168, 170 do
            if x ~= 169 or y ~= 7 then
                game.walls[x .. ":" .. y] = true
            end
        end
    end

    -- Placement failure should stay silent while health still changes.
    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    player_health.damage(game, player, 50, false,
        attacker, causes.HIT)

    harness.equal(#jiyva_summons(ctx, player), 0)

    for _, message in ipairs(messages) do
        harness.falsy(message == "Nothing happens.")
    end
end

-- Run all categories against the same production health and summon owners.
function test.run(ctx)
    first_threshold(ctx)
    higher_thresholds(ctx)
    ineligible_hits(ctx)
    blocked_ejection(ctx)
end

return test
