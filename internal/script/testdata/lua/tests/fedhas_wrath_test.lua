-- Fedhas wrath uses real corpse items, saved hostile summons, and the
-- ordinary map service fixture. No test-local component schema is needed.
local component = require("constants.component")
local fedhas = require("policy.religion.wrath.fedhas")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local items = require("ids.items")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- A player with source-sized health, skills, and piety is enough for all
-- three wrath branches without borrowing definitions from production.
local function player_at(ctx, x, worship_god)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, x, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, { level = 12 })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.COMBAT, { shield_blocks = 0 })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 15,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = worship_god or gods.NO_GOD,
        penance = {},
    })

    return player
end

-- Fix the first branch choice while using zero for subsequent random
-- choices, so saved monster placement remains deterministic in this test.
local function with_choice(ctx, choice)
    local owner = setmetatable({}, { __index = ctx })
    local cards = 0

    function owner:random(stream, bound)
        if stream == streams.CARDS then
            cards = cards + 1

            if cards == 1 then
                return choice
            end
        end

        return 0
    end

    return owner
end

-- A real corpse body at an empty visible cell becomes a skeleton while
-- its hostile spore carries Fedhas's god ID and the player as target.
local function corpse_spore(ctx)
    local player = player_at(ctx, 20)
    local body = ctx:create()

    ctx:add(body, component.ITEM, {
        kind_id = items.CORPSE_BODY,
        quantity = 1,
    })
    ctx:add(body, component.CORPSE, {
        monster_id = monsters.MONS_HUMAN,
        freshness = 7,
        appearance = 9,
    })
    ctx:add(body, component.POSITION, {
        level_id = 1,
        x = 22,
        y = 10,
    })

    local owner = with_choice(fixture.context(ctx, player), 0)

    harness.truthy(fedhas.apply(owner, player))
    harness.equal(ctx:get(body, component.ITEM).kind_id,
        items.CORPSE_SKELETON)
    harness.equal(ctx:get(body, component.CORPSE).freshness, 110)
    harness.equal(ctx:get(body, component.CORPSE).appearance, 1)

    local found = false

    for _, entity in ipairs(ctx:query({ component.MONSTER_SPORE })) do
        local position = ctx:get(entity, component.POSITION)

        if position.x == 22 and position.y == 10 then
            harness.equal(ctx:get(entity, component.ACTOR).kind_id,
                monsters.MONS_BALLISTOMYCETE_SPORE)
            harness.equal(ctx:get(entity, component.SUMMON).source_id,
                gods.FEDHAS)
            harness.equal(ctx:get(entity,
                component.MONSTER_SPORE).target, player)
            found = true
        end
    end

    harness.truthy(found, "Fedhas created no corpse spore")
end

-- On a spacious visible floor, the first ring fills with ordinary plants
-- and a farther ring gains source-god oklobs in separate angular arcs.
local function spacious_ring(ctx)
    local player = player_at(ctx, 100)
    local owner = with_choice(fixture.context(ctx, player), 2)

    harness.falsy(fedhas.apply(owner, player))

    local nearby = 0
    local distant = 0

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local summon = ctx:get(entity, component.SUMMON)

        if summon.source_id == gods.FEDHAS then
            local kind = ctx:get(entity, component.ACTOR).kind_id

            if kind == monsters.MONS_PLANT then
                nearby = nearby + 1
            elseif kind == monsters.MONS_OKLOB_PLANT then
                distant = distant + 1
            end
        end
    end

    harness.equal(nearby, 8)
    harness.truthy(distant > 0, "Fedhas placed no distant oklob")
end

-- A floor with no open ring cells cannot fabricate plants; it permits
-- the surrounding card or wrath owner to continue its next action.
local function blocked_ring(ctx)
    local player = player_at(ctx, 200)
    local site = fixture.context(ctx, player)

    for dy = -7, 7 do
        for dx = -7, 7 do
            if dx ~= 0 or dy ~= 0 then
                site.walls[(200 + dx) .. ":" .. (10 + dy)] = true
            end
        end
    end

    harness.truthy(fedhas.apply(with_choice(site, 2), player))
end

-- No corpse makes the first branch fall straight into the god avatar's
-- nature spell. It does not spend a second wrath branch choice.
local function empty_corpse_fallback(ctx)
    local player = player_at(ctx, 300)
    local owner = with_choice(fixture.context(ctx, player), 0)

    harness.truthy(fedhas.apply(owner, player))
    harness.truthy(ctx:get(player, component.HEALTH).current < 100,
        "empty corpse branch did not cast its fallback nature spell")
end

-- A cramped map cannot use the distant oklob ring. The two selected
-- neighboring cells receive mushrooms through the same summon owner.
local function cramped_ring(ctx)
    local player = player_at(ctx, 350)
    local site = fixture.context(ctx, player)

    for dy = -7, 7 do
        for dx = -7, 7 do
            if dx ~= 0 or dy ~= 0 then
                site.walls[(350 + dx) .. ":" .. (10 + dy)] = true
            end
        end
    end

    site.walls["351:10"] = nil
    site.walls["350:11"] = nil
    site.walls["349:10"] = nil

    harness.falsy(fedhas.apply(with_choice(site, 2), player))

    local count = 0

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local summon = ctx:get(entity, component.SUMMON)
        local position = ctx:get(entity, component.POSITION)

        if summon.source_id == gods.FEDHAS and
            math.abs(position.x - 350) <= 1 and
            math.abs(position.y - 10) <= 1 then
            harness.equal(ctx:get(entity, component.ACTOR).kind_id,
                monsters.MONS_WANDERING_MUSHROOM)
            count = count + 1
        end
    end

    harness.equal(count, 2)
end

-- Exercise each independently located outcome in one source world.
function test.run(ctx)
    corpse_spore(ctx)
    spacious_ring(ctx)
    blocked_ring(ctx)
    empty_corpse_fallback(ctx)
    cramped_ring(ctx)
end

return test
