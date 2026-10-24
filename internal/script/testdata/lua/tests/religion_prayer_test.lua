-- Prayer consults the actual altar record shape while the real ECS owns
-- devotion. A context proxy supplies the one cell that this isolated Lua
-- test does not have; Game tests use the host grid and saved records.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local gods = require("constants.gods")
local harness = require("tests.harness")
local intents = require("constants.intent")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local prayer = require("policy.religion.prayer")
local mutation_records = require("policy.mutations.records")
local play = require("policy.input.play")
local commands = require("policy.input.commands")
local species = require("ids.species")
local terrain = require("constants.terrain")

local test = {}

-- Create a real player with live eligibility and saved worship state.
local function player(ctx)
    local actor = ctx:create()

    ctx:add(actor, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Prayer test",
    })
    ctx:add(actor, component.WALLET, {})
    ctx:add(actor, component.RELIGION_WORSHIP, {})

    return actor
end

-- Return the host's typed record shape and reject RNG before acceptance.
local function altar(ctx, god_id)
    local proxy = setmetatable({}, { __index = ctx })
    local saved_id = god_id
    local draws = 0
    local changes = 0

    function proxy:get(entity, name)
        if name == component.POSITION then
            return {
                level_id = 1,
                x = 4,
                y = 5,
            }
        end

        return ctx:get(entity, name)
    end

    function proxy:cell()
        return terrain.DNGN_RANDOM_ALTAR
    end

    function proxy:records_at(_, x, y)
        harness.equal(x, 4)
        harness.equal(y, 5)

        return {
            {
                kind = effects.SOURCE_FEATURE,
                source_id = "test_altar",
                identity = terrain.DNGN_RANDOM_ALTAR,
                x = x,
                y = y,
                pending = false,
                overridden = false,
                arguments = { god_id = saved_id },
            },
        }
    end

    function proxy:random(_, bound)
        draws = draws + 1
        harness.truthy(bound > 0)

        return 0
    end

    function proxy:replace_record_string(_, x, y, source_id, kind,
        identity, key, expected, replacement)
        harness.equal(x, 4)
        harness.equal(y, 5)
        harness.equal(source_id, "test_altar")
        harness.equal(kind, effects.SOURCE_FEATURE)
        harness.equal(identity, terrain.DNGN_RANDOM_ALTAR)
        harness.equal(key, "god_id")
        harness.equal(expected, saved_id)
        saved_id = replacement
        changes = changes + 1
    end

    function proxy:draws()
        return draws
    end

    function proxy:changes()
        return changes
    end

    function proxy:god_id()
        return saved_id
    end

    return proxy
end

local position = {
    level_id = 1,
    x = 4,
    y = 5,
}

-- A normal altar first asks for confirmation. A refused conversion leaves
-- worship and RNG unchanged, and a stale target cannot be accepted later.
local function ordinary(ctx)
    local actor = player(ctx)
    local site = altar(ctx, gods.ZIN)
    local offer = prayer.prepare(site, actor, {}, position)

    harness.truthy(offer.confirmation)
    harness.equal(offer.confirmation_id, gods.ZIN)
    harness.equal(site:draws(), 0)
    harness.equal(ctx:get(actor, component.RELIGION_WORSHIP).god_id,
        gods.NO_GOD)

    local stale = prayer.prepare(site, actor, {
        forced = true,
        target_id = gods.TROG,
    }, position)

    harness.truthy(stale.message)
    harness.equal(site:draws(), 0)

    local accepted = prayer.prepare(site, actor, {
        forced = true,
        target_id = gods.ZIN,
    }, position)

    harness.equal(accepted.intent.kind, intents.PRAYER)
    harness.equal(accepted.intent.target_id, gods.ZIN)
    harness.equal(accepted.cost, 10)

    prayer.resolve(site, actor, accepted.intent)

    harness.equal(ctx:get(actor, component.RELIGION_WORSHIP).god_id,
        gods.ZIN)
    harness.equal(site:changes(), 0)

    local own = prayer.prepare(site, actor, {}, position)

    harness.truthy(own.message)
    harness.falsy(own.confirmation)
end

-- A forbidden Beogh conversion is rejected before either confirmation or
-- RNG. The same player may still pray at an eligible altar later.
local function forbidden(ctx)
    local actor = player(ctx)
    local site = altar(ctx, gods.BEOGH)
    local result = prayer.prepare(site, actor, {}, position)

    harness.truthy(result.message)
    harness.falsy(result.confirmation)
    harness.equal(site:draws(), 0)
    harness.equal(ctx:get(actor, component.RELIGION_WORSHIP).god_id,
        gods.NO_GOD)
end

-- A scenery-created Xom altar has a dedicated terrain ID instead of a DES
-- record. Prayer must still offer the patron before charging any time.
local function xom_scenery_altar(ctx)
    local actor = player(ctx)
    local site = setmetatable({}, { __index = ctx })

    function site:cell()
        return terrain.DNGN_ALTAR_XOM
    end

    function site:records_at()
        error("Xom scenery altar should not need a source vault record")
    end

    local offer = prayer.prepare(site, actor, {}, position)

    harness.equal(offer.confirmation_id, gods.XOM)
    harness.equal(ctx:get(actor, component.RELIGION_WORSHIP).god_id,
        gods.NO_GOD)
end

-- An unknown altar stays unknown until the accepted timed action. The
-- winning god and the level record then agree, using one sorted-ID draw.
local function ecumenical(ctx)
    local actor = player(ctx)
    local site = altar(ctx, gods.ECUMENICAL)
    local offer = prayer.prepare(site, actor, {}, position)

    harness.truthy(offer.confirmation)
    harness.equal(offer.confirmation_id, gods.ECUMENICAL)
    harness.equal(site:draws(), 0)

    local accepted = prayer.prepare(site, actor, {
        forced = true,
        target_id = gods.ECUMENICAL,
    }, position)

    prayer.resolve(site, actor, accepted.intent)

    local worship = ctx:get(actor, component.RELIGION_WORSHIP)

    harness.equal(site:draws(), 1)
    harness.equal(site:changes(), 1)
    harness.equal(site:god_id(), worship.god_id)
    harness.truthy(worship.god_id ~= gods.ECUMENICAL)
end

-- A Forlorn character cannot worship any source god. The unknown altar must
-- reject before offering a prompt or drawing a random god indefinitely.
local function ecumenical_without_candidate(ctx)
    local actor = player(ctx)
    local site = altar(ctx, gods.ECUMENICAL)

    mutation_records.grant_acquired(ctx, actor,
        mutations.MUT_FORLORN, 1)

    local decision = prayer.prepare(site, actor, {}, position)

    harness.truthy(decision.message)
    harness.falsy(decision.confirmation)
    harness.equal(site:draws(), 0)
end

-- Stair keys on an altar request prayer before shop or stair routing.
-- Without an altar, the existing stair key retains its original action.
local function input_route()
    for _, key in ipairs({ "<", ">" }) do
        local decision = play.route({
            key = key,
            on_altar = true,
            on_shop = true,
        })

        harness.equal(decision.action, "step")
        harness.equal(decision.kind, commands.pray)
    end

    local stairs = play.route({ key = "<" })

    harness.equal(stairs.kind, commands.upstairs)
end

-- Run independent altar scenarios against one production ECS world.
function test.run(ctx)
    ordinary(ctx)
    forbidden(ctx)
    xom_scenery_altar(ctx)
    ecumenical(ctx)
    ecumenical_without_candidate(ctx)
    input_route()
end

return test
