-- A drawn targeted card is already spent when its aim prompt appears.
-- Its pre-aim effect and sampled tier must survive retries and restore.
local area = require("policy.combat.torment_area")
local abilities = require("ids.abilities")
local card_operations = require("constants.card_operations")
local card_phases = require("constants.card_phases")
local cards = require("ids.cards")
local command = require("policy.commands.abilities")
local component = require("constants.component")
local decks = require("ids.decks")
local draw = require("policy.religion.cards.draw")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local operations = require("policy.religion.cards.operations")
local selection_kinds = require("constants.selection_kinds")
local species = require("ids.species")
local state = require("policy.religion.cards.state")
local streams = require("constants.rng_streams")

local test = {}

-- Register the production ability definitions before crossing the generic
-- command boundary; the deck test does not redeclare their behavior.
require("policy.abilities.nemelex")

-- Reconstruct the production component fields to simulate a save load,
-- rather than retaining a reference to the pre-prompt Lua table.
local function restored(owned)
    return {
        counts = owned.counts,
        stack = owned.stack,
        pending_kind = owned.pending_kind,
        pending_phase = owned.pending_phase,
        pending_deck = owned.pending_deck,
        pending_cards = owned.pending_cards,
        pending_target_count = owned.pending_target_count,
        pending_selected = owned.pending_selected,
        pending_failed = owned.pending_failed,
        pending_tier = owned.pending_tier,
        pending_dx = owned.pending_dx,
        pending_dy = owned.pending_dy,
    }
end

-- The real draw owner decrements the deck, and the real play owner saves
-- TARGET_CARD before any user response can cancel the direction chooser.
function test.run(ctx)
    local player = ctx:create()
    local game = fixture.context(ctx, player)
    local torment_count = 0

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Targeted card tester",
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.NEMELEX_XOBEH,
        piety = 200,
    })

    local owned = state.get(game, player)

    owned.counts[decks.DESTRUCTION] = 1
    state.set(game, player, owned)

    function game:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        harness.truthy(bound == 900 or bound == 2700)

        return 0
    end

    local sample = draw.sample
    local torment = area.apply

    draw.sample = function(_, deck)
        harness.equal(deck, decks.DESTRUCTION)

        return cards.PAIN
    end
    area.apply = function()
        torment_count = torment_count + 1
    end

    local ok, message = pcall(function()
        local drawn = operations.prepare(game, player, {
            kind = card_operations.DRAW,
            deck_id = decks.DESTRUCTION,
        })

        harness.equal(drawn.card_id, cards.PAIN)
        harness.equal(state.get(game, player).counts[decks.DESTRUCTION], 0)

        local prompt = operations.play(game, player, {})

        harness.equal(prompt.selection.kind, selection_kinds.CELL)
        harness.equal(torment_count, 1)
        harness.equal(state.get(game, player).pending_phase,
            card_phases.TARGET_CARD)
        harness.equal(state.get(game, player).pending_tier, 2)

        state.set(game, player, restored(state.get(game, player)))

        local retry = operations.play(game, player, {})

        harness.equal(retry.selection.kind, selection_kinds.CELL)
        harness.equal(torment_count, 1)

        local confirmation = command.prepare(game, player, {
            ability_id = abilities.NEMELEX_DRAW_DESTRUCTION,
            cancelled = true,
        })

        harness.truthy(confirmation.confirmation)
        harness.equal(state.get(game, player).pending_phase,
            card_phases.CONFIRM_WASTE)

        local resume = command.prepare(game, player, {
            ability_id = abilities.NEMELEX_DRAW_DESTRUCTION,
            cancelled = true,
        })

        harness.equal(resume.selection.kind, selection_kinds.CELL)
        harness.equal(state.get(game, player).pending_phase,
            card_phases.TARGET_CARD)

        confirmation = command.prepare(game, player, {
            ability_id = abilities.NEMELEX_DRAW_DESTRUCTION,
            cancelled = true,
        })

        harness.truthy(confirmation.confirmation)

        local ready = command.prepare(game, player, {
            ability_id = abilities.NEMELEX_DRAW_DESTRUCTION,
            forced = true,
        })

        harness.truthy(ready.intent)
        harness.equal(state.get(game, player).counts[decks.DESTRUCTION], 0)
        harness.equal(torment_count, 1)

        operations.finish(game, player)
        harness.equal(state.get(game, player).pending_kind,
            card_operations.NONE)
        harness.equal(state.get(game, player).counts[decks.DESTRUCTION], 0)
    end)

    draw.sample = sample
    area.apply = torment

    if not ok then
        error(message)
    end
end

return test
