-- Dark-god wrath draws exercise saved combat and status state through the
-- production Lua schemas. Fixed card draws expose source branch ordering.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local kikubaaqudgha = require("policy.religion.wrath.kikubaaqudgha")
local monsters = require("ids.monsters")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local trog = require("policy.religion.wrath.trog")
local yredelemnul = require("policy.religion.wrath.yredelemnul")

local test = {}

-- Only card choices are fixed; all saved ECS writes use the real context.
local function with_draws(ctx, draws)
    local owner = setmetatable({}, { __index = ctx })
    local used = 0

    -- Check every scripted card bound before delegating other owner streams.
    function owner:random(stream, bound)
        if stream ~= streams.CARDS then
            return ctx:random(stream, bound)
        end

        used = used + 1
        local value = draws[used]

        harness.truthy(value ~= nil, "missing dark wrath draw")
        harness.truthy(value >= 0 and value < bound,
            "invalid dark wrath draw")

        return value
    end

    -- Make source roll counts observable without copying branch code.
    function owner:draws_used()
        return used
    end

    return owner
end

-- Position and identity use the same registered records as the player.
local function player_at(ctx, level)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.ACTOR, {
        kind_id = monsters.MONS_HUMAN,
        speed = 10,
    })
    ctx:add(player, component.PROGRESSION, {
        level = level,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 20,
        y = 20,
    })
    ctx:add(player, component.HEALTH, {
        current = 100,
        max = 100,
    })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 15,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.NO_GOD,
    })

    return player
end

-- A high-level Kiku draw torments the living player through the real area
-- owner; the source gate draws before resistance or curse selection.
local function kiku_torment(ctx)
    local player = player_at(ctx, 27)
    local owner = with_draws(fixture.context(ctx, player), { 0, 0 })

    harness.truthy(kikubaaqudgha.apply(owner, player))
    harness.equal(ctx:get(player, component.HEALTH).current, 51)
    harness.equal(owner:draws_used(), 2)
end

-- Yred's common servant path writes a permanent hostile summon with its
-- actual god source and an indexed first servant from the source list.
local function yred_servant(ctx)
    local player = player_at(ctx, 2)
    local owner = with_draws(fixture.context(ctx, player), {
        0, 0, 0, 1, 0, 0,
    })

    harness.truthy(yredelemnul.apply(owner, player))

    local summoned = ctx:query({ component.SUMMON })
    local creature = summoned[#summoned]

    harness.equal(ctx:get(creature, component.ACTOR).kind_id,
        monsters.MONS_WIGHT)
    harness.equal(ctx:get(creature, component.SUMMON).source_id,
        gods.YREDELEMNUL)
    harness.equal(ctx:get(creature, component.SUMMON).expires_aut, 0)
end

-- Trog's physical branch drains Strength with the shared saved recovery
-- owner after the branch and effect rolls.
local function trog_strength(ctx)
    local player = player_at(ctx, 5)
    local owner = with_draws(fixture.context(ctx, player), {
        1, 1, 0, 2,
    })

    harness.truthy(trog.apply(owner, player))
    harness.equal(ctx:get(player, component.STAT_LOSS).strength, 3)
    harness.equal(owner:draws_used(), 4)
end

-- The level-one budget buys two bears; both are permanent hostile god
-- summons and enter the shared saved frenzy state immediately.
local function trog_berserkers(ctx)
    local player = player_at(ctx, 1)
    local owner = with_draws(fixture.context(ctx, player), {
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
    })
    local before = #ctx:query({ component.SUMMON })

    harness.truthy(trog.apply(owner, player))

    local summoned = ctx:query({ component.SUMMON })

    harness.equal(#summoned - before, 2)

    for index = before + 1, #summoned do
        local creature = summoned[index]

        harness.equal(ctx:get(creature, component.ACTOR).kind_id,
            monsters.MONS_BLACK_BEAR)
        harness.equal(ctx:get(creature, component.SUMMON).source_id,
            gods.TROG)
        harness.equal(ctx:get(creature, component.SUMMON).expires_aut, 0)
        harness.truthy(ctx:get(creature,
            component.MONSTER_ALLEGIANCE).frenzy_aut > 0)
    end
end

-- Paralysis writes an actual saved player status and returns false so the
-- caller skips its bonus debilitation, just as this source case does.
local function trog_paralysis(ctx)
    local player = player_at(ctx, 5)
    local owner = with_draws(fixture.context(ctx, player), {
        1, 1, 3, 0,
    })

    harness.falsy(trog.apply(owner, player))
    harness.equal(ctx:get(player,
        component.PLAYER_PARALYSIS).remaining_aut, 20)
end

-- Run independent saved-state outcomes in the shared Lua rule context.
function test.run(ctx)
    kiku_torment(ctx)
    yred_servant(ctx)
    trog_strength(ctx)
    trog_berserkers(ctx)
    trog_paralysis(ctx)
end

return test
