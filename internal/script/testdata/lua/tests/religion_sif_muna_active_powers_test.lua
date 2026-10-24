-- Sif's powers are discovered as ordinary Lua ability files. The first
-- contract checks their live piety gates before any spell selection occurs.
local abilities = require("ids.abilities")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local channel_state = require("policy.religion.sif_muna.channel")
local jobs = require("ids.jobs")
local piety = require("policy.religion.piety")
local registry = require("policy.abilities.registry")
local records = require("policy.character.spell_records")
local species = require("ids.species")
local spells = require("ids.spells")

local test = {}

-- Use registered production schemas so a field rename in game code also
-- fails this test, instead of surviving in a private test-only record.
local function player(ctx)
    local entity = ctx:create()

    ctx:add(entity, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Sif tester",
    })
    ctx:add(entity, component.SKILLS, { entries = {} })
    ctx:add(entity, component.MAGIC, {
        current = 3,
        max = 10,
    })
    ctx:add(entity, component.HEALTH, {
        current = 10,
        max = 10,
    })
    ctx:add(entity, component.PROGRESSION, {
        level = 27,
    })
    ctx:add(entity, component.RELIGION_WORSHIP, {
        god_id = gods.SIF_MUNA,
        piety = piety.breakpoint(1),
        penance = {},
    })

    return entity
end

-- A successful Channel grants a saved timer and regenerates MP at the
-- source's per-action rate. The actual ECS magic pool remains authoritative.
local function channel_recovery(ctx, worshipper)
    local game = fixture.context(ctx, worshipper)

    function game:random(_, bound)
        return bound - 1
    end

    local magic = ctx:get(worshipper, component.MAGIC)

    magic.current = 0
    ctx:set(worshipper, component.MAGIC, magic)
    registry.get(abilities.SIF_MUNA_CHANNEL_ENERGY).resolve(game,
        worshipper)

    local channel = ctx:get(worshipper,
        component.RELIGION_SIF_CHANNEL)

    harness.truthy(channel)
    harness.truthy(channel.remaining_aut > 0)
    channel_state.tick(game, worshipper, 10)

    magic = ctx:get(worshipper, component.MAGIC)
    harness.truthy(magic.current >= 3 and magic.current <= 5)
end

-- Forgetting goes through the live spell record owner. The selection prompt
-- is free, while the committed ability removes only the known slot.
local function forget_spell(ctx, worshipper)
    records.start(ctx, worshipper,
        { spells.SPELL_MAGIC_DART },
        { spells.SPELL_MAGIC_DART }, {})

    local game = fixture.context(ctx, worshipper)
    local definition = registry.get(abilities.SIF_MUNA_FORGET_SPELL)
    local prompt = definition.prepare(game, worshipper, {})

    harness.equal(prompt.selection.kind, "spell")
    harness.equal(prompt.selection.options[1].id,
        spells.SPELL_MAGIC_DART)

    function game:random(_, bound)
        return bound - 1
    end

    harness.equal(definition.prepare(game, worshipper, {
        spell_id = spells.SPELL_MAGIC_DART,
        forced = true,
    }), nil)
    definition.resolve(game, worshipper, {
        spell_id = spells.SPELL_MAGIC_DART,
    })

    local entry = records.find(ctx, worshipper,
        spells.SPELL_MAGIC_DART)

    harness.equal(entry.state.known_slot, 0)
    harness.truthy(entry.state.in_library)
end

-- Exegesis offers a library-only spell without assigning it a known slot.
-- Its successful preparation must still use spell targeting and resources.
local function exegesis_selection(ctx, worshipper)
    records.grant_library(ctx, worshipper,
        { spells.SPELL_SWIFTNESS })

    local game = fixture.context(ctx, worshipper)
    local definition = registry.get(abilities.SIF_MUNA_DIVINE_EXEGESIS)
    local prompt = definition.prepare(game, worshipper, {})

    harness.equal(prompt.selection.kind, "spell")

    local offered = false

    for _, option in ipairs(prompt.selection.options) do
        offered = offered or option.id == spells.SPELL_SWIFTNESS
    end

    harness.truthy(offered)

    -- Ordinary level gating must not hide a higher-level library spell
    -- from this divine cast. Swiftness is level three here; the player is
    -- set to level one before the production preflight runs.
    local progress = ctx:get(worshipper, component.PROGRESSION)

    progress.level = 1
    ctx:set(worshipper, component.PROGRESSION, progress)

    harness.equal(definition.prepare(game, worshipper, {
        spell_id = spells.SPELL_SWIFTNESS,
    }), nil)
    harness.equal(records.find(ctx, worshipper,
        spells.SPELL_SWIFTNESS).state.known_slot, 0)
end

-- Sif unlocks Channel, Forget, and Exegesis at one, three, and four
-- stars. The same registry drives both the terminal menu and command gate.
function test.run(ctx)
    local worshipper = player(ctx)
    local channel = registry.get(abilities.SIF_MUNA_CHANNEL_ENERGY)
    local forget = registry.get(abilities.SIF_MUNA_FORGET_SPELL)
    local exegesis = registry.get(abilities.SIF_MUNA_DIVINE_EXEGESIS)

    harness.truthy(channel, "Channel Magic is not registered")
    harness.truthy(forget, "Forget Spell is not registered")
    harness.truthy(exegesis, "Divine Exegesis is not registered")
    harness.truthy(channel.available(ctx, worshipper))
    harness.falsy(forget.available(ctx, worshipper))
    harness.falsy(exegesis.available(ctx, worshipper))

    local worship = ctx:get(worshipper, component.RELIGION_WORSHIP)

    worship.piety = piety.breakpoint(4)
    ctx:set(worshipper, component.RELIGION_WORSHIP, worship)
    harness.truthy(forget.available(ctx, worshipper))
    harness.truthy(exegesis.available(ctx, worshipper))

    channel_recovery(ctx, worshipper)
    forget_spell(ctx, worshipper)
    exegesis_selection(ctx, worshipper)

    worship.god_id = gods.TROG
    ctx:set(worshipper, component.RELIGION_WORSHIP, worship)
    harness.falsy(channel.available(ctx, worshipper))
    harness.falsy(forget.available(ctx, worshipper))
    harness.falsy(exegesis.available(ctx, worshipper))
end

return test
