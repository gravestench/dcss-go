local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local statuses = require("policy.magic.effects.statuses.player")
local monster_spell = require("policy.ai.spell")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    records.grant_acquired(ctx, player, mutations.MUT_WILD_MAGIC, 2)
    records.grant_acquired(ctx, player,
        mutations.MUT_SUBDUED_MAGIC, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_ANTI_WIZARDRY, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_INNATE_CASTER, 1)

    harness.equal(effects.sum(ctx, player,
        capabilities.SPELL_FAILURE_ADJUSTMENT), 10,
        "Wild, Subdued, and Anti-Wizardry combine in raw failure")
    harness.equal(effects.sum(ctx, player,
        capabilities.SPELL_POWER_GAIN), 6,
        "Wild Magic raises spell power by three tenths per level")
    harness.equal(effects.sum(ctx, player,
        capabilities.SPELL_POWER_LOSS), 3,
        "Subdued Magic reduces spell power by three tenths per level")
    harness.equal(effects.sum(ctx, player,
        capabilities.SPELLCASTING_SCALE_BONUS), 200,
        "Innate Caster replaces school training with Spellcasting")

    harness.equal(statuses.silence_radius(ctx, player), -1,
        "an ordinary player has no silence aura")

    records.grant_acquired(ctx, player, mutations.MUT_SILENCE_AURA, 1)

    harness.equal(statuses.silence_radius(ctx, player), 1,
        "Silence Aura creates a permanent one-cell silence radius")

    local monster = ctx:create()
    local encounter = setmetatable({}, { __index = ctx })

    function encounter.player()
        return player
    end

    harness.equal(monster_spell.choose(encounter, monster,
        { x = 2, y = 1 }, { x = 1, y = 1 }), nil,
        "Silence Aura prevents adjacent monster spell selection")
end

return test
