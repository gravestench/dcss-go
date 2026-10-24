-- Beogh's active powers read one worship owner and the ordinary ability
-- command bridge. These checks use production ECS schemas and catalog IDs.
local abilities = require("ids.abilities")
local commands = require("policy.commands.abilities")
local component = require("constants.component")
local costs = require("policy.abilities.beogh.costs")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local piety = require("policy.religion.piety")
local registry = require("policy.abilities.registry")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- Use the same saved worship, magic, and skill components that command
-- resolution reads; only player lookup is supplied by this rule fixture.
local function worshipper(ctx)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })

    function game:player()
        return player
    end

    function game:visible()
        return true
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HILL_ORC,
        job_id = jobs.JOB_FIGHTER,
        name = "Beogh ability tester",
    })
    ctx:add(player, component.PROGRESSION, { level = 10 })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 10,
        y = 10,
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.BEOGH,
        piety = piety.breakpoint(4),
        penance = {},
    })

    return game, player
end

-- Source ranks are two, four, five, and six stars. Beogh penance removes
-- all four actions without changing their saved menu definitions.
local function gates(game, player)
    local worship = game:get(player, component.RELIGION_WORSHIP)

    worship.piety = piety.breakpoint(2)
    game:set(player, component.RELIGION_WORSHIP, worship)

    harness.truthy(costs.available(game, player, 2))
    harness.falsy(costs.available(game, player, 4))
    harness.truthy(registry.usable_now(game, player,
        registry.get(abilities.BEOGH_SMITING)))

    worship.piety = piety.breakpoint(6)
    worship.penance[gods.BEOGH] = 1
    game:set(player, component.RELIGION_WORSHIP, worship)

    harness.falsy(costs.available(game, player, 2))
    harness.falsy(costs.available(game, player, 6))

    worship.penance[gods.BEOGH] = 0
    game:set(player, component.RELIGION_WORSHIP, worship)

    harness.truthy(costs.available(game, player, 6))
end

-- The source invocation formula uses effective Invocations and piety;
-- three widened draws determine failure at the accepted action boundary.
local function source_failure(game, player)
    local worship = game:get(player, component.RELIGION_WORSHIP)

    worship.piety = 100
    game:set(player, component.RELIGION_WORSHIP, worship)

    harness.equal(costs.failure_chance(game, player, 40, 5, 20),
        35)
    harness.equal(costs.failure_chance(game, player, 30, 6, 20),
        25)

    local draws = 0

    function game:random(stream)
        harness.equal(stream, streams.RELIGION)
        draws = draws + 1

        return 0
    end

    harness.truthy(costs.failed(game, player, 40, 5, 20))
    harness.equal(draws, 3)
end

-- A prepared ability must carry both generic selected entities through
-- the intent bridge; the item and follower owners will validate them.
local function selected_entities(game, player)
    local selected = commands.prepare(game, player, {
        ability_id = abilities.BEOGH_SMITING,
        dx = 1,
        dy = 0,
        item_id = 123,
        target_id = "456",
    })

    harness.equal(selected.intent.item_id, 123)
    harness.equal(selected.intent.target_id, "456")
end

-- Each case uses the same player but resets worship and RNG state before
-- the next behavior; no test-only schema mirrors production definitions.
function test.run(ctx)
    local game, player = worshipper(ctx)

    gates(game, player)
    source_failure(game, player)
    selected_entities(game, player)
end

return test
