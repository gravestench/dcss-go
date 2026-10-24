-- Yredelemnul's branch choices use production summon, undead-base, and
-- religion schemas. The test pins card draws but imports all live IDs.
local attitudes = require("constants.attitude")
local branches = require("ids.branches")
local categories = require("constants.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local pool = require("policy.population.pool")
local souls = require("policy.religion.wrath.yredelemnul.souls")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local yredelemnul = require("policy.religion.wrath.yredelemnul")
local zombie_base = require("policy.population.zombie_base")

local test = {}

-- Give each scenario a separate positioned player. The real ECS stores
-- worship and progression, while the sparse grid fixture supplies cells.
local function player_at(ctx, x, level, god_id)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        x, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.PROGRESSION, {
        level = level,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = god_id,
        penance = {},
    })

    return player
end

-- The card stream fixes source branch order and population choice while
-- unrelated monster HP and spell streams use minimum fixture draws.
local function with_draws(ctx, player, draws)
    local owner = setmetatable({}, {
        __index = fixture.context(ctx, player),
    })
    local used = 0

    function owner:random(stream, bound)
        if stream ~= streams.CARDS then
            return 0
        end

        used = used + 1
        local value = draws[used]

        harness.truthy(value ~= nil, "unexpected Yred wrath draw")
        harness.truthy(value >= 0 and value < bound,
            "Yred wrath draw exceeds source bound")

        return value
    end

    function owner:draws_used()
        return used
    end

    return owner
end

-- Select a Centaur from the effective, committed D:8 rows without copying
-- population rarity numbers into this test file.
local function centaur_roll()
    local choices = pool.at_depth(branches.BRANCH_DUNGEON, 8)
    local offset = 0

    for _, row in ipairs(choices) do
        if row.id == monsters.MONS_CENTAUR then
            return offset
        end

        offset = offset + row.weight
    end

    error("D:8 has no Centaur zombie base")
end

-- Both source forms retain the chosen monster's derived-undead record
-- and Yredelemnul's permanent hostile god source after placement.
local function derived_undead(ctx, skeleton)
    local player = player_at(ctx, skeleton and 20 or 30,
        1, gods.NO_GOD)
    local draws = {
        0, -- servant half
        0, 0, -- one attempt at XL1
        0, -- one-in-level derived undead
        skeleton and 0 or 1,
        1, -- do not round D:6's bonus upward
        centaur_roll(),
        0, -- first adjacent placement cell
    }
    local owner = with_draws(ctx, player, draws)

    harness.truthy(yredelemnul.apply(owner, player))
    harness.equal(owner:draws_used(), #draws)

    local expected = skeleton and monsters.MONS_SKELETON or
        monsters.MONS_ZOMBIE
    local found = false

    for _, entity in ipairs(ctx:query({ component.SUMMON_UNDEAD })) do
        local actor = ctx:get(entity, component.ACTOR)
        local state = ctx:get(entity, component.SUMMON)

        if actor.kind_id == expected and
            state.source_id == gods.YREDELEMNUL then
            harness.equal(state.source_category, categories.GODS)
            harness.equal(state.attitude, attitudes.HOSTILE)
            harness.equal(state.expires_aut, 0)
            harness.equal(ctx:get(entity,
                component.SUMMON_UNDEAD).base_kind_id,
                monsters.MONS_CENTAUR)
            found = true
        end
    end

    harness.truthy(found, "Yredelemnul created no derived undead")
end

-- One permanent friendly undead gift is reclaimed before any servant
-- count draw. Its second, temporary counterpart must remain untouched.
local function reclaim_one(ctx)
    local player = player_at(ctx, 50, 10, gods.YREDELEMNUL)
    local gift = fixture.actor(ctx, monsters.MONS_WIGHT,
        51, 10, 20)
    local temporary = fixture.actor(ctx, monsters.MONS_WIGHT,
        52, 10, 20)

    for _, entry in ipairs({
        { entity = gift, expiry = 0 },
        { entity = temporary, expiry = 100 },
    }) do
        ctx:add(entry.entity, component.SUMMON, {
            owner = player,
            source_category = categories.GODS,
            source_id = gods.YREDELEMNUL,
            expires_aut = entry.expiry,
            attitude = attitudes.FRIENDLY,
            heads = 0,
        })
    end

    local owner = with_draws(ctx, player, { 0, 0 })

    harness.truthy(souls.eligible(owner, player, gift))
    harness.falsy(souls.eligible(owner, player, temporary))
    harness.truthy(yredelemnul.apply(owner, player))
    harness.equal(owner:draws_used(), 2)
    harness.falsy(ctx:has(gift, component.ACTOR))
    harness.truthy(ctx:has(temporary, component.ACTOR))
end

-- An empty reclaim attempt falls into the servant branch; source does
-- not redraw the top-level Yredelemnul coinflip.
local function empty_reclaim_fallback(ctx)
    local player = player_at(ctx, 70, 2, gods.YREDELEMNUL)
    local owner = with_draws(ctx, player, {
        0, 0, -- undead branch, attempted reclaim
        0, 0, -- one servant attempt
        1, -- ordinary servant, not a derived undead
        0, 0, -- first roster member, first placement cell
    })

    harness.truthy(yredelemnul.apply(owner, player))
    harness.equal(owner:draws_used(), 7)
end

-- The depth formula uses the source rounding draw and caps at D:27.
-- This is a catalog selector fact, separate from deity branch selection.
local function population_depth(ctx)
    local player = player_at(ctx, 90, 1, gods.NO_GOD)
    local owner = with_draws(ctx, player, { 1, 0 })

    harness.equal(zombie_base.depth(owner, 1), 8)
    harness.equal(zombie_base.depth(owner, 27), 27)
    harness.equal(owner:draws_used(), 2)
end

-- A sealed ring makes every exact servant placement fail. Wrath returns
-- after that failure instead of retrying the same impossible summon forever.
local function blocked_servants(ctx)
    local player = player_at(ctx, 110, 2, gods.NO_GOD)
    local site = fixture.context(ctx, player)

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                site.walls[(110 + dx) .. ":" .. (10 + dy)] = true
            end
        end
    end

    local owner = setmetatable({}, { __index = site })
    local used = 0

    function owner:random(stream, bound)
        if stream ~= streams.CARDS then
            return 0
        end

        used = used + 1

        if used == 1 then
            return 0
        end

        if bound == 2 then
            return 1
        end

        return 0
    end

    harness.truthy(yredelemnul.apply(owner, player))
    harness.truthy(used < 20,
        "blocked servant placement kept retrying")
end

-- Run all branch scenarios against live component schemas.
function test.run(ctx)
    derived_undead(ctx, false)
    derived_undead(ctx, true)
    reclaim_one(ctx)
    empty_reclaim_fallback(ctx)
    population_depth(ctx)
    blocked_servants(ctx)
end

return test
