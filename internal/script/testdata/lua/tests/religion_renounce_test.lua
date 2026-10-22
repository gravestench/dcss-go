-- Renunciation uses the production ability registry and worship schema.
-- The test checks prompt state without recreating a private transition rule.
local abilities = require("ids.abilities")
local commands = require("policy.commands.abilities")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local intents = require("constants.intent")
local jobs = require("ids.jobs")
local registry = require("policy.abilities.registry")
local species = require("ids.species")

local test = {}

-- Bind a real ECS player to a source patron before exercising the ability.
local function worshipper(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_BERSERKER,
        name = "Renunciation test",
    })
    ctx:add(player, component.WALLET, {})
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.TROG,
        piety = 50,
    })

    return player
end

-- The two target IDs must differ and both must bind the same live patron.
-- A stale answer cannot skip a prompt or trigger the leave path.
local function prompts(ctx, player)
    local input = { ability_id = abilities.RENOUNCE_RELIGION }
    local first = commands.prepare(ctx, player, input)

    harness.truthy(first.confirmation)
    harness.falsy(first.intent)

    input.forced = true
    input.target_id = first.confirmation_id

    local second = commands.prepare(ctx, player, input)

    harness.truthy(second.confirmation)
    harness.truthy(second.confirmation_id ~= first.confirmation_id)
    harness.equal(ctx:get(player, component.RELIGION_WORSHIP).god_id,
        gods.TROG)

    input.target_id = "stale answer"

    local stale = commands.prepare(ctx, player, input)

    harness.truthy(stale.message)
    harness.falsy(stale.intent)

    input.target_id = second.confirmation_id

    local accepted = commands.prepare(ctx, player, input)

    harness.equal(accepted.intent.kind, intents.PLAYER_ABILITY)
    harness.equal(accepted.cost, 10)

    return accepted.intent
end

-- The resolved ability calls the common leave path, which records debt and
-- makes the menu entry disappear for a newly godless player.
function test.run(ctx)
    local player = worshipper(ctx)
    local intent = prompts(ctx, player)

    registry.resolve(ctx, player, intent, 10)

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(state.god_id, gods.NO_GOD)
    harness.truthy(state.penance[gods.TROG] > 0)
    harness.falsy(registry.usable_now(ctx, player,
        registry.get(abilities.RENOUNCE_RELIGION)))
end

return test
