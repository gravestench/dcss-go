-- Ignis anoints the strongest suitable monster in sight. The marker
-- belongs to the monster and later owners read it for combat and travel.
local component = require("constants.component")
local attitude = require("constants.attitude")
local behaviors = require("constants.ai_behaviors")
local flavours = require("constants.attack_flavours")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local ignis = require("policy.religion.wrath.ignis")
local champion = require("policy.religion.wrath.ignis_champion")
local energy = require("policy.monster_energy")
local monsters = require("ids.monsters")
local senses = require("policy.character.senses")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local intent = require("constants.intent")

local test = {}

-- A second equal-HD body replaces the first only on its reservoir draw.
-- Cell order and Lua file load order cannot pick a permanent winner.
local function check_equal_strength(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        72, 10, 100)
    local first = fixture.actor(ctx, monsters.MONS_OGRE,
        73, 10, 30)
    local second = fixture.actor(ctx, monsters.MONS_OGRE,
        74, 10, 30)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 2,
    })

    local owner = fixture.context(ctx, player)

    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)

        return bound == 2 and 1 or 0
    end

    harness.equal(champion.target(owner, player).entity, first)

    function owner:random(stream, _)
        harness.equal(stream, streams.CARDS)

        return 0
    end

    harness.equal(champion.target(owner, player).entity, second)
end

-- A low-HD Orc precedes an Ogre in sight order. Ignis must choose the
-- higher HD rather than the first eligible actor or the newest entity.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        60, 10, 100)
    local orc = fixture.actor(ctx, monsters.MONS_ORC,
        61, 10, 10)
    local ogre = fixture.actor(ctx, monsters.MONS_OGRE,
        62, 10, 30)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 2,
    })
    ctx:add(ogre, component.AI, {
        behavior = behaviors.SLEEP,
    })

    local owner = setmetatable({}, {
        __index = fixture.context(ctx, player),
    })
    local draw = 0

    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)

        draw = draw + 1

        if draw == 1 then
            harness.equal(bound, 3)

            return 1
        end

        return 0
    end

    harness.truthy(ignis.apply(owner, player))
    harness.falsy(ctx:has(orc, component.IGNIS_FIRE_CHAMPION))
    harness.truthy(ctx:has(ogre, component.IGNIS_FIRE_CHAMPION))
    harness.equal(ctx:get(ogre, component.AI).behavior,
        behaviors.SEEK)

    harness.equal(energy.cost(owner, {
        intent = intent.MOVE,
        kind_id = monsters.MONS_OGRE,
        actor = ctx:id(ogre),
    }), 6)

    ctx:add(ogre, component.MONSTER_ENCHANT, {
        invisible_aut = 10,
    })

    harness.equal(senses.perceive(owner, player, ogre,
        true, true), "visible")
    harness.equal(champion.attack_flavour(ctx, ogre,
        flavours.PLAIN), flavours.FIRE)

    -- An existing champion's effective first attack is Fire, so Ignis
    -- must find another vessel rather than repeat the enchantment.
    harness.equal(champion.target(owner, player).entity, orc)

    -- Both temporary and permanent summons are barred from stairs and
    -- therefore cannot be chosen by Ignis, even when they have more HD.
    local summoned = fixture.actor(ctx, monsters.MONS_OGRE,
        63, 10, 30)

    ctx:add(summoned, component.SUMMON, {
        owner = player,
        expires_aut = 100,
        attitude = attitude.HOSTILE,
    })
    harness.equal(champion.target(owner, player).entity, orc)

    ctx:get(summoned, component.SUMMON).expires_aut = 0
    harness.equal(champion.target(owner, player).entity, orc)

    check_equal_strength(ctx)
end

return test
