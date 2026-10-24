-- A card aim must run the same ally safety check as the source tracer.
-- The projectile resolver is observed at its public boundary so a failed
-- aim cannot appear to succeed by merely suppressing damage downstream.
local attitudes = require("constants.attitude")
local card_operations = require("constants.card_operations")
local card_phases = require("constants.card_phases")
local cards = require("ids.cards")
local component = require("constants.component")
local decks = require("ids.decks")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local play = require("policy.religion.cards.play")
local projectile = require("policy.magic.effects.zaps.projectile")
local selection_kinds = require("constants.selection_kinds")
local species = require("ids.species")
local state = require("policy.religion.cards.state")

local test = {}

-- An allied rat in the ray requires explicit consent. Reaiming around it
-- should proceed without consuming any separate friendly-fire decision.
function test.run(ctx)
    local player = ctx:create()
    local game = fixture.context(ctx, player)
    local ally = fixture.actor(ctx, monsters.MONS_RAT, 8, 7)
    local shots = 0

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })
    ctx:add(player, component.RELIGION_WORSHIP, { piety = 100 })
    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(ally, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    local original = projectile.fire

    projectile.fire = function()
        shots = shots + 1
    end

    local ok, message = pcall(function()
        local warning = effects.apply(game, player, cards.VITRIOL, {
            tier = 0,
            power = 180,
            dx = 2,
            dy = 0,
        })

        harness.truthy(warning.friendly_confirmation)
        harness.equal(shots, 0)

        effects.apply(game, player, cards.VITRIOL, {
            tier = 0,
            power = 180,
            dx = 2,
            dy = 0,
            confirmed_friendly = true,
        })

        harness.equal(shots, 1)

        effects.apply(game, player, cards.VITRIOL, {
            tier = 0,
            power = 180,
            dx = 0,
            dy = 2,
        })

        harness.equal(shots, 2)

        -- The card owner saves the ray across confirmation and returns to
        -- aim on a declined prompt. Accepting then fires that saved ray.
        local owned = state.get(game, player)

        owned.pending_kind = card_operations.DRAW
        owned.pending_phase = card_phases.TARGET_CARD
        owned.pending_deck = decks.DESTRUCTION
        owned.pending_cards = { cards.VITRIOL }
        owned.pending_target_count = 1
        owned.pending_selected = 1
        owned.pending_tier = 0
        state.set(game, player, owned)

        local question = play.run(game, player, { dx = 2, dy = 0 })

        harness.truthy(question.confirmation)
        harness.equal(state.get(game, player).pending_phase,
            card_phases.CONFIRM_FRIENDLY)
        harness.equal(state.get(game, player).pending_dx, 2)
        harness.truthy(play.run(game, player, {}).confirmation)
        harness.equal(play.run(game, player, { cancelled = true })
            .selection.kind, selection_kinds.CELL)
        harness.equal(state.get(game, player).pending_phase,
            card_phases.TARGET_CARD)

        harness.truthy(play.run(game, player,
            { dx = 2, dy = 0 }).confirmation)
        harness.truthy(play.run(game, player,
            { forced = true }).ready)
        harness.equal(shots, 3)
        harness.equal(state.get(game, player).pending_dx, 0)
    end)

    projectile.fire = original

    if not ok then
        error(message)
    end
end

return test
