
local capabilities = require("constants.mutation_capabilities")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local statuses = require("policy.magic.effects.statuses.player")
local monster_spell = require("policy.ai.spell")
local harness = require("tests.harness")

local test = {}

-- Mutation spell power rolls stay within the named spell RNG bound.
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

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    ctx:add(monster, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 1,
    })

    ctx:add(monster, component.ACTOR, {
        kind_id = monsters.MONS_ORC_WIZARD,
        speed = 10,
    })

    ctx:add(monster, component.HEALTH, {
        current = 10,
        max = 10,
    })

    local encounter = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to spell effect fixture actor so player-only branches execute on that entity.
    function encounter.player()
        return player
    end

    -- Choose the first monster spell from the source 200-way selection.
    function encounter.random(_, stream, bound)
        harness.equal(stream, "monster_spell", "spell selection stream")
        harness.equal(bound, 200, "source spell roll bound")

        return 0
    end

    harness.equal(monster_spell.choose(encounter, monster, player, false), nil,
        "Silence Aura prevents adjacent wizard spell selection")
end

return test
