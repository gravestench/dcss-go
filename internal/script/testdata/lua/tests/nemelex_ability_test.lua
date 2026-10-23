-- Nemelex abilities expose the deck owner through the ordinary worship
-- ability menu, command preflight, and saved card-operation phases.
local abilities = require("ids.abilities")
local command = require("policy.commands.abilities")
local component = require("constants.component")
local card_phases = require("constants.card_phases")
local cards = require("ids.cards")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local nemelex = require("policy.abilities.nemelex")
local registry = require("policy.abilities.registry")
local species = require("ids.species")
local state = require("policy.religion.cards.state")
local selection_kinds = require("constants.selection_kinds")
local decks = require("ids.decks")
local piety = require("policy.religion.piety")

local test = {}

-- A live player uses the actual rank thresholds and resource components.
local function worshipper(ctx)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })

    function game:player()
        return player
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Nemelex ability tester",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 10,
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.NEMELEX_XOBEH,
        piety = piety.breakpoint(1),
    })

    local owned = state.get(game, player)

    owned.counts[decks.ESCAPE] = 1
    state.set(game, player, owned)

    return game, player
end

-- Draw appears on joining with a card, while the three stronger
-- operations unlock at their source ranks. No Go menu owns those gates.
local function rank_gates(game, player)
    local worship = game:get(player, component.RELIGION_WORSHIP)

    worship.piety = 15
    game:set(player, component.RELIGION_WORSHIP, worship)

    harness.truthy(registry.usable_now(game, player,
        registry.get(abilities.NEMELEX_DRAW_ESCAPE)))
    harness.falsy(registry.usable_now(game, player,
        registry.get(abilities.NEMELEX_TRIPLE_DRAW)))

    worship.piety = piety.breakpoint(3)
    game:set(player, component.RELIGION_WORSHIP, worship)

    harness.truthy(registry.usable_now(game, player,
        registry.get(abilities.NEMELEX_TRIPLE_DRAW)))
    harness.falsy(registry.usable_now(game, player,
        registry.get(abilities.NEMELEX_DEAL_FOUR)))

    worship.piety = piety.breakpoint(5)
    game:set(player, component.RELIGION_WORSHIP, worship)

    harness.truthy(registry.usable_now(game, player,
        registry.get(abilities.NEMELEX_DEAL_FOUR)))
    harness.truthy(registry.usable_now(game, player,
        registry.get(abilities.NEMELEX_STACK_FIVE)))
end

-- The ordinary command preparation creates a no-time deck menu. The
-- selected ability ID stays on the replayed terminal command.
local function deck_menu(game, player)
    local prompt = command.prepare(game, player, {
        ability_id = abilities.NEMELEX_TRIPLE_DRAW,
    })

    harness.equal(prompt.selection.kind, selection_kinds.CARD)
    harness.equal(prompt.selection.options[1].id, decks.ESCAPE)
    harness.truthy(prompt.selection.options[1].label:find("1 card)", 1, true))
    harness.equal(state.get(game, player).counts[decks.ESCAPE], 1)
end

-- Source failure bases use separate Invocations and piety divisors; Deal
-- Four has its own expression instead of the ordinary invocation template.
local function source_costs(game, player)
    local worship = game:get(player, component.RELIGION_WORSHIP)

    worship.piety = 200
    game:set(player, component.RELIGION_WORSHIP, worship)

    harness.equal(nemelex.failure_chance(game, player,
        abilities.NEMELEX_TRIPLE_DRAW), 50)
    harness.equal(nemelex.failure_chance(game, player,
        abilities.NEMELEX_DEAL_FOUR), 62)
    harness.equal(nemelex.failure_chance(game, player,
        abilities.NEMELEX_STACK_FIVE), 72)

    local magic = game:get(player, component.MAGIC)

    magic.current = 1
    game:set(player, component.MAGIC, magic)

    local rejected = command.prepare(game, player, {
        ability_id = abilities.NEMELEX_TRIPLE_DRAW,
    })

    harness.truthy(rejected.message)
    harness.equal(state.get(game, player).counts[decks.ESCAPE], 1)
end

-- A failed Triple Draw happens after deck choice but before sampling. It
-- spends time while preserving cards, MP, and piety, as source ability.cc
-- pays resources only for a successful ability.
local function failed_triple(ctx)
    local game, player = worshipper(ctx)
    local worship = game:get(player, component.RELIGION_WORSHIP)
    local owned = state.get(game, player)

    worship.piety = 200
    game:set(player, component.RELIGION_WORSHIP, worship)
    owned.counts[decks.ESCAPE] = 3
    state.set(game, player, owned)

    local failure_draws = 0
    local bounds = { 100, 101, 101 }

    function game:random(_, bound)
        failure_draws = failure_draws + 1
        harness.equal(bound, bounds[failure_draws])

        return 0
    end

    command.prepare(game, player, {
        ability_id = abilities.NEMELEX_TRIPLE_DRAW,
    })

    harness.equal(failure_draws, 3)

    local decision = command.prepare(game, player, {
        ability_id = abilities.NEMELEX_TRIPLE_DRAW,
        target_id = decks.ESCAPE,
    })

    harness.truthy(decision.intent)
    harness.equal(state.get(game, player).pending_phase,
        card_phases.FAILED)
    harness.equal(state.get(game, player).counts[decks.ESCAPE], 3)
    harness.equal(failure_draws, 3)

    registry.resolve(game, player, decision.intent, 10)

    harness.equal(game:get(player, component.MAGIC).current, 10)
    harness.equal(game:get(player,
        component.RELIGION_WORSHIP).piety_hysteresis, 0)
    harness.equal(game:get(player,
        component.RELIGION_WORSHIP).piety, 200)
    harness.equal(state.get(game, player).pending_kind, "")
end

-- Stack Five's final answer becomes one timed ability. Source costs are
-- paid only on success, after the saved stack has its confirmed order.
local function successful_stack(ctx)
    local game, player = worshipper(ctx)
    local owned = state.get(game, player)
    local worship = game:get(player, component.RELIGION_WORSHIP)

    owned.counts[decks.ESCAPE] = 2
    state.set(game, player, owned)
    worship.piety = 200
    game:set(player, component.RELIGION_WORSHIP, worship)

    local samples = { 0, 9 }
    local index = 0

    function game:random(_, bound)
        if bound == 100 then
            return 99
        end

        if bound == 101 then
            return 100
        end

        harness.equal(bound, 23)
        index = index + 1

        return samples[index]
    end

    local question = command.prepare(game, player, {
        ability_id = abilities.NEMELEX_STACK_FIVE,
    })

    harness.truthy(question.confirmation)

    local decks_prompt = command.prepare(game, player, {
        ability_id = abilities.NEMELEX_STACK_FIVE,
        forced = true,
    })

    harness.truthy(decks_prompt.selection)

    for _ = 1, 2 do
        command.prepare(game, player, {
            ability_id = abilities.NEMELEX_STACK_FIVE,
            target_id = decks.ESCAPE,
        })
    end

    local ready = command.prepare(game, player, {
        ability_id = abilities.NEMELEX_STACK_FIVE,
        target_id = "done",
    })

    harness.truthy(ready.intent)
    harness.equal(#state.get(game, player).stack, 2)
    harness.truthy(registry.usable_now(game, player,
        registry.get(abilities.NEMELEX_STACK_FIVE)))
    registry.resolve(game, player, ready.intent, 10)

    harness.equal(index, 2)
    harness.equal(game:get(player, component.MAGIC).current, 5)
    harness.equal(game:get(player,
        component.RELIGION_WORSHIP).piety, 191)
    harness.equal(state.get(game, player).stack[2], cards.CLOUD)
end

-- A second confirmation inherits the terminal command's first accepted
-- flag. Cancelling it must win over a saved failed invocation result.
local function cancel_second_stack_prompt(ctx)
    local game, player = worshipper(ctx)
    local owned = state.get(game, player)
    local worship = game:get(player, component.RELIGION_WORSHIP)

    owned.stack = { cards.CLOUD }
    owned.counts[decks.ESCAPE] = 2
    state.set(game, player, owned)
    worship.piety = 200
    game:set(player, component.RELIGION_WORSHIP, worship)

    function game:random(_, bound)
        harness.truthy(bound == 100 or bound == 101)

        return 0
    end

    local replace = command.prepare(game, player, {
        ability_id = abilities.NEMELEX_STACK_FIVE,
    })

    harness.truthy(replace.confirmation)

    local short = command.prepare(game, player, {
        ability_id = abilities.NEMELEX_STACK_FIVE,
        forced = true,
    })

    harness.truthy(short.confirmation)

    local cancelled = command.prepare(game, player, {
        ability_id = abilities.NEMELEX_STACK_FIVE,
        forced = true,
        cancelled = true,
    })

    harness.truthy(cancelled.message)
    harness.equal(state.get(game, player).pending_kind, "")
    harness.equal(state.get(game, player).stack[1], cards.CLOUD)
    harness.equal(state.get(game, player).counts[decks.ESCAPE], 2)
end

-- A normal Escape draw plays its catalog-selected Elixir before the one
-- timed intent, then clears its saved card only after ability resolution.
local function draw_elixir(ctx)
    local game, player = worshipper(ctx)
    local owned = state.get(game, player)
    local worship = game:get(player, component.RELIGION_WORSHIP)
    local draws = {
        {
            bound = 100,
            value = 99,
        },
        {
            bound = 101,
            value = 100,
        },
        {
            bound = 101,
            value = 100,
        },
        {
            bound = 23,
            value = 9,
        },
        {
            bound = 900,
            value = 899,
        },
        {
            bound = 2700,
            value = 2699,
        },
        {
            bound = 3,
            value = 1,
        },
    }
    local index = 0

    owned.counts[decks.ESCAPE] = 1
    state.set(game, player, owned)
    worship.piety = 200
    game:set(player, component.RELIGION_WORSHIP, worship)

    function game:random(_, bound)
        index = index + 1
        harness.equal(bound, draws[index].bound)

        return draws[index].value
    end

    local prepared = command.prepare(game, player, {
        ability_id = abilities.NEMELEX_DRAW_ESCAPE,
    })

    harness.truthy(prepared.intent)
    harness.equal(state.get(game, player).counts[decks.ESCAPE], 0)
    harness.equal(state.get(game, player).pending_phase,
        card_phases.READY)
    harness.equal(game:get(player,
        component.RELIGION_CARD_ELIXIR).remaining_aut, 20)

    registry.resolve(game, player, prepared.intent, 10)

    harness.equal(state.get(game, player).pending_kind, "")
    harness.equal(index, #draws)
end

-- Each helper above invokes production registry and component owners; only
-- the player lookup is adapted for the standalone Lua harness.
function test.run(ctx)
    local game, player = worshipper(ctx)

    rank_gates(game, player)
    deck_menu(game, player)
    state.clear(game, player)

    local owned = state.get(game, player)

    owned.counts[decks.ESCAPE] = 1
    state.set(game, player, owned)

    source_costs(game, player)
    failed_triple(ctx)
    successful_stack(ctx)
    cancel_second_stack_prompt(ctx)
    draw_elixir(ctx)
end

return test
