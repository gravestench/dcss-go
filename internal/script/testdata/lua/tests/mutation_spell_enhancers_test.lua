
local component = require("constants.component")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local skills = require("ids.skills")
local species = require("ids.species")
local spells = require("ids.spells")
local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local power = require("policy.magic.power")
local fighter = require("policy.combat.fighter")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Bind spell enhancers player lookup to this owner while preserving live ECS component reads.
local function player_context(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to spell enhancers fixture actor so player-only branches execute on that entity.
    function proxy.player()
        return player
    end

    return proxy
end

-- Seed exact school skill points before comparing mutation spell enhancers.
local function trained_player(ctx)
    local player = ctx:create()
    local points = formulas.skill_points_needed(5, 0)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Spell enhancer test",
    })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, component.SKILLS, {
        entries = {
            {
                id = skills.SK_HEXES,
                level = 5,
                points = points,
            },

            {
                id = skills.SK_NECROMANCY,
                level = 5,
                points = points,
            },
        },
    })
    ctx:add(player, component.HEALTH, {
        current = 100,
        max = 100,
    })

    return player
end

-- Half-health Augmentation keeps only one tier.
function test.run(ctx)
    local player = trained_player(ctx)
    local hex = catalog.get("spells", spells.SPELL_CONFUSING_TOUCH)
    local necro = catalog.get("spells",
        spells.SPELL_BORGNJORS_REVIVIFICATION)
    local mixed = catalog.get("spells", spells.SPELL_ANGUISH)

    harness.equal(power.cast(ctx, player, hex), 10,
        "unmodified trained Hexes power")
    harness.equal(power.cast(ctx, player, necro), 10,
        "unmodified trained Necromancy power")

    records.grant_acquired(ctx, player,
        mutations.MUT_HEX_ENHANCER, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_NECRO_ENHANCER, 1)

    harness.equal(power.cast(ctx, player, hex), 15,
        "Bedeviling applies one Hexes enhancement")
    harness.equal(power.cast(ctx, player, necro), 15,
        "In Touch with Death applies one Necromancy enhancement")
    -- Enhancers are applied in sequence with source integer rounding after each step.
    harness.equal(power.cast(ctx, player, mixed), 22,
        "multi-school enhancement levels stack with each-step rounding")

    records.grant_acquired(ctx, player,
        mutations.MUT_AUGMENTATION, 3)

    harness.equal(power.cast(ctx, player, hex), 33,
        "full-health Augmentation boosts spell power after enhancers")

    local health = ctx:get(player, component.HEALTH)
    health.current = 50
    ctx:set(player, component.HEALTH, health)

    harness.equal(power.cast(ctx, player, hex), 21,
        "half-health Augmentation keeps only one tier")

    health.current = 49
    ctx:set(player, component.HEALTH, health)

    -- Health thresholds are read at cast time rather than cached on mutation grant.
    harness.equal(power.cast(ctx, player, hex), 15,
        "Augmentation disappears below its first HP threshold")

    local battle = player_context(ctx, player)
    local baseline_slay = fighter.attack(battle, {}).slay

    health.current = 100
    ctx:set(player, component.HEALTH, health)

    harness.equal(fighter.attack(battle, {}).slay, baseline_slay + 9,
        "full-health Augmentation adds three slay per active tier")
end

return test
