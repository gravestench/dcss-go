-- Cheibriados uses the same live tension calculation as Seal Doors. These
-- cases check the quiet and dangerous ends against saved player state.
local cheibriados = require("policy.religion.wrath.cheibriados")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local species = require("ids.species")
local confusion = require("policy.magic.player_confusion")
local zap = require("policy.magic.effects.zaps.ids").component
local streams = require("constants.rng_streams")
local tension = require("policy.combat.monster_seal_tension")

local test = {}

-- The actual player and monster components feed tension and the ordinary
-- Sleep, Slow, Haste, stat-loss, and penance owners.
local function player_at(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 10, 10, 10)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
    })
    ctx:add(player, component.DURATIONS, {
        haste_aut = 100,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.NO_GOD,
        penance = {
            [gods.CHEIBRIADOS] = 10,
        },
    })

    return player
end

-- Pin card draws while leaving status and recovery streams with the real
-- runtime. Recording bounds catches a changed source branch before effects.
local function with_draws(ctx, player, draws)
    local owner = setmetatable({}, {
        __index = fixture.context(ctx, player),
    })
    local bounds = {}

    function owner:random(stream, bound)
        if stream ~= streams.CARDS then
            return ctx:random(stream, bound)
        end

        bounds[#bounds + 1] = bound
        local value = draws[#bounds]

        harness.truthy(value ~= nil, "missing Cheibriados card draw")
        harness.truthy(value >= 0 and value < bound)

        return value
    end

    function owner:bounds()
        return bounds
    end

    return owner
end

-- With no threat, random2(0) contributes zero and Chei drains one random
-- stat. Clearing Haste still spends its threshold-crossing coinflip.
local function quiet_wrath(ctx, player)
    local owner = with_draws(ctx, player, { 0, 0, 0, 0 })

    harness.equal(tension.current(owner, player), 0)
    harness.truthy(cheibriados.apply(owner, player))
    harness.equal(ctx:get(player, component.DURATIONS).haste_aut, 0)
    harness.equal(ctx:get(player, component.STAT_LOSS).strength, 1)
    harness.equal(owner:bounds()[1], 2)
    harness.equal(owner:bounds()[2], 5)
    harness.equal(owner:bounds()[3], 6)
    harness.equal(owner:bounds()[4], 3)
end

-- A visible strong foe produces the highest severity. The falling-through
-- branch makes noise, sleeps, slows, and reduces penance twice.
local function urgent_wrath(ctx, player)
    fixture.actor(ctx, monsters.MONS_ORC_WARLORD, 11, 10, 100)

    local owner = with_draws(ctx, player, { 16, 0, 1, 0 })
    local score = tension.current(owner, player)

    harness.truthy(score > 16)

    -- The source counts live confusion and Slow before selecting a wrath
    -- tier; their saved components must affect the shared score too.
    confusion.extend(owner, player, 1)
    harness.equal(tension.current(owner, player), score * 2)
    ctx:remove(player, zap.PLAYER_CONFUSION)

    ctx:add(player, component.PLAYER_SLOW, {
        remaining_aut = 10,
    })
    harness.equal(tension.current(owner, player),
        math.floor(score * 3 / 2))
    ctx:remove(player, component.PLAYER_SLOW)

    harness.truthy(cheibriados.apply(owner, player))
    harness.truthy(ctx:get(player,
        component.PLAYER_SLEEP).remaining_aut > 0)
    harness.truthy(ctx:get(player,
        component.PLAYER_SLOW).remaining_aut > 0)
    harness.equal(ctx:get(player,
        component.RELIGION_WORSHIP).penance[gods.CHEIBRIADOS], 8)
    harness.equal(owner:bounds()[1], score)
    harness.equal(owner:bounds()[2], 20)
    harness.equal(owner:bounds()[3], 3)
    harness.equal(owner:bounds()[4], 10)
end

function test.run(ctx)
    local player = player_at(ctx)

    quiet_wrath(ctx, player)
    urgent_wrath(ctx, player)
end

return test
