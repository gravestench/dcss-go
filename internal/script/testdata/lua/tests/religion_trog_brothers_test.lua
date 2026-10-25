-- Brothers in Arms creates a real, saved god-sourced ally. The source
-- thresholds determine its kind before ordinary placement and rage run.
local attitudes = require("constants.attitude")
local brothers = require("policy.abilities.trog.brothers")
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local categories = require("constants.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local piety = require("policy.religion.piety")
local species = require("ids.species")
local expiry = require("systems.magic_summon_expiry")

local test = {}

-- Force the first weighted result in each power band, then the final
-- result, without changing the production roster or source thresholds.
local function source_bands(game)
    -- The first weighted slot checks each threshold's lower choice.
    function game:random(_, bound)
        return 0
    end

    harness.equal(brothers.kind(game, 100), monsters.MONS_BLACK_BEAR)
    harness.equal(brothers.kind(game, 101),
        monsters.MONS_TWO_HEADED_OGRE)
    harness.equal(brothers.kind(game, 141), monsters.MONS_TROLL)
    harness.equal(brothers.kind(game, 181), monsters.MONS_CYCLOPS)

    -- The last slot checks alternate choices and repeated weight entries.
    function game:random(_, bound)
        return bound - 1
    end

    harness.equal(brothers.kind(game, 100), monsters.MONS_POLAR_BEAR)
    harness.equal(brothers.kind(game, 101), monsters.MONS_OGRE)
    harness.equal(brothers.kind(game, 141), monsters.MONS_IRON_TROLL)
    harness.equal(brothers.kind(game, 181), monsters.MONS_STONE_GIANT)
end

-- An actual summoned actor keeps Trog as its source and shares its
-- extended Berserk end time with the saved summon expiry.
function test.run(ctx)
    local player = ctx:create()
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 20,
        y = 20,
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.TROG,
        piety = 200,
    })

    source_bands(game)

    -- Minimum draws make a giant and an open adjacent cell deterministic.
    function game:random(_, bound)
        return 0
    end

    local creature = brothers.summon(game, player)

    harness.truthy(creature)
    harness.equal(ctx:get(creature, component.ACTOR).kind_id,
        monsters.MONS_CYCLOPS)

    local summon = ctx:get(creature, component.SUMMON)
    local rage = ctx:get(creature, component.MONSTER_ALLEGIANCE)

    harness.equal(summon.owner, player)
    harness.equal(summon.source_category, categories.GODS)
    harness.equal(summon.source_id, gods.TROG)
    harness.equal(summon.attitude, attitudes.FRIENDLY)
    harness.truthy(rage.frenzy_aut > 0)
    harness.equal(summon.expires_aut, 0)

    -- Player-time cannot dismiss a Brother while its own actions have
    -- not used up Berserk. Its final monster action ends both enchantments.
    expiry.update(game, player)
    harness.truthy(ctx:has(creature, component.SUMMON))
    allegiance.tick(game, creature, rage.frenzy_aut)
    expiry.update(game, creature)
    harness.falsy(ctx:has(creature, component.SUMMON))

    creature = brothers.summon(game, player)
    harness.truthy(creature)
    brothers.dismiss(game, player)
    harness.falsy(ctx:has(creature, component.SUMMON))

    -- Eight blocked adjacent cells make a successful invocation fizzle,
    -- but the piety cost remains committed as in source Crawl.
    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                game.walls[(20 + dx) .. ":" .. (20 + dy)] = true
            end
        end
    end

    local before = ctx:get(player, component.RELIGION_WORSHIP).piety

    brothers.resolve(game, player)
    harness.truthy(ctx:get(player,
        component.RELIGION_WORSHIP).piety < before)

    game.walls = {}
    local second = brothers.summon(game, player)

    harness.truthy(second)
    piety.offend(game, player, 0, 1)
    harness.falsy(ctx:has(second, component.SUMMON))
end

return test
