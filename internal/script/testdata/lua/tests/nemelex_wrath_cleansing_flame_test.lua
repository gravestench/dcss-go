-- The Shining One's wrath uses the same holy blast as monster Cleansing
-- Flame, centered on the player with source-level power and collateral.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local shining_one = require("policy.religion.wrath.shining_one")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- Use real player defenses and positioned actors so the production blast
-- owner performs its ordinary armour, holiness, and geometry checks.
local function scene(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 40, 20, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 12,
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })
    ctx:add(player, component.COMBAT, {
        shield_blocks = 0,
    })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 15,
        intelligence = 10,
        dexterity = 10,
    })

    local nearby = fixture.actor(ctx, monsters.MONS_ORC, 41, 20, 100)
    local holy = fixture.actor(ctx, monsters.MONS_ANGEL, 40, 21, 100)
    local distant = fixture.actor(ctx, monsters.MONS_ORC, 46, 20, 100)

    return player, nearby, holy, distant
end

-- Fix only the wrath gate and the damage dice. Distinct source streams
-- remain visible in the bounds so a changed power formula fails here.
local function with_draws(ctx)
    local owner = setmetatable({}, { __index = ctx })
    local card_bounds = {}
    local spell_bounds = {}

    function owner:random(stream, bound)
        if stream == streams.CARDS then
            card_bounds[#card_bounds + 1] = bound

            return 3
        end

        if stream == streams.MONSTER_SPELL then
            spell_bounds[#spell_bounds + 1] = bound

            return 0
        end

        return ctx:random(stream, bound)
    end

    function owner:card_bounds()
        return card_bounds
    end

    function owner:spell_bounds()
        return spell_bounds
    end

    return owner
end

-- The god's two d12 dice at XL12 hit the player and nearby orc, while a
-- holy angel and a body outside radius two retain their full HP.
function test.run(ctx)
    local player, nearby, holy, distant = scene(ctx)
    local owner = with_draws(fixture.context(ctx, player))

    harness.truthy(shining_one.apply(owner, player))
    harness.equal(ctx:get(player, component.HEALTH).current, 98)
    harness.equal(ctx:get(nearby, component.HEALTH).current, 98)
    harness.equal(ctx:get(holy, component.HEALTH).current, 100)
    harness.equal(ctx:get(distant, component.HEALTH).current, 100)
    harness.equal(#owner:card_bounds(), 1)
    harness.equal(owner:card_bounds()[1], 7)
    harness.equal(owner:spell_bounds()[1], 12)
end

return test
