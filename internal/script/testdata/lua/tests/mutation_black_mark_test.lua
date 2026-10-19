
local capabilities = require("constants.mutation_capabilities")
local armour_egos = require("constants.armour_egos")
local component = require("constants.component")
local items = require("ids.items")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local species = require("ids.species")
local catalog = require("policy.catalog")
local effects = require("policy.mutations.effects.registry")
local monster_stats = require("policy.combat.monster_stats")
local monster_drain = require("policy.combat.monster_drain")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Seed black mark attacker and target independently before the reaction mutates either.
local function fixture(ctx)
    local player = ctx:create()
    local monster = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Black Mark test",
    })
    ctx:add(monster, component.ACTOR, {
        kind_id = monsters.MONS_ORC_WIZARD,
        speed = 10,
    })
    ctx:add(monster, component.HEALTH, {
        current = 100,
        max = 100,
    })
    records.grant_acquired(ctx, player, mutations.MUT_BLACK_MARK, 1)

    return player, monster
end

-- Keep Black Mark effect selection and emitted combat messages observable.
local function battle_context(ctx, player, choice, chance)
    local battle = setmetatable({}, { __index = ctx })
    local chose = false

    -- Bind policy ownership to black mark fixture actor so player-only branches execute on that entity.
    function battle.player()
        return player
    end

    -- Choose the five-way proc and three-way Black Mark effect independently.
    function battle.random(_, stream, bound)
        if stream == "mutation" and bound == 5 then
            return chance or 0
        end

        if stream == "mutation" and bound == 3 and not chose then
            chose = true
            return choice
        end

        return bound - 1
    end

    return battle
end

-- Apply one controlled melee hit so Black Mark can choose its effect.
local function strike(ctx, player, monster, choice, chance)
    local battle = battle_context(ctx, player, choice, chance)
    local hit = {
        target = monster,
        damage = 5,
    }

    effects.trigger(battle, player, capabilities.AFTER_MELEE_HIT, hit)
end

-- Equip a resistance source before testing Black Mark drain selection.
local function equip_life_protection(ctx, monster)
    local shield = ctx:create()

    ctx:add(shield, component.ITEM, {
        kind_id = items.ARM_BUCKLER,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = armour_egos.POSITIVE_ENERGY,
    })
    ctx:add(shield, component.CARRIED_BY, {
        holder = monster,
    })
    ctx:add(shield, component.EQUIPPED, {
        slot = "shield",
    })
end

-- Undead monsters cannot be selected for Black Mark draining.
function test.run(ctx)
    local player, monster = fixture(ctx)

    strike(ctx, player, monster, 0)

    local status = ctx:get(monster, component.MONSTER_ENFEEBLE)

    -- Force one effect branch at a time to test the weighted Black Mark choices.
    harness.truthy(status and status.antimagic_aut > 0,
        "Black Mark can disrupt a spellcasting monster")

    local weak_player, weak_monster = fixture(ctx)

    strike(ctx, weak_player, weak_monster, 1)

    status = ctx:get(weak_monster, component.MONSTER_ENFEEBLE)
    harness.truthy(status and status.weak_aut >= 60,
        "Black Mark can weaken an attacking monster")

    local drain_player, drain_monster = fixture(ctx)

    strike(ctx, drain_player, drain_monster, 2)

    local drained = ctx:get(drain_monster, component.MONSTER_DRAINED)
    local definition = catalog.get("monsters", monsters.MONS_ORC_WIZARD)

    harness.truthy(drained and drained.remaining_aut > 0,
        "Black Mark can apply temporary monster drain")
    harness.equal(ctx:get(drain_monster, component.HEALTH).current, 96,
        "draining also deals source two-to-four negative damage")
    harness.equal(monster_stats.hit_dice(ctx, drain_monster, definition),
        definition.hd - 1,
        "drain lowers effective monster hit dice")

    for _ = 1, math.ceil(drained.remaining_aut / 10) do
        monster_drain.tick(ctx, drain_monster)
    end

    -- Drain must recover through the monster status timer, not the player turn.
    harness.falsy(ctx:has(drain_monster, component.MONSTER_DRAINED),
        "temporary drain expires on the monster clock")
    harness.equal(monster_stats.hit_dice(ctx, drain_monster, definition),
        definition.hd,
        "monster hit dice recover when drain expires")

    local undead = catalog.get("monsters", monsters.MONS_WIGHT)

    -- Holiness filtering is checked after effect selection and before drain damage.
    harness.equal(monster_drain.resistance(ctx, drain_monster, undead), 3,
        "undead monsters cannot be selected for Black Mark draining")

    local shielded_player, shielded_monster = fixture(ctx)

    equip_life_protection(ctx, shielded_monster)
    local shielded_battle = battle_context(ctx, shielded_player, 2)

    harness.equal(monster_drain.resistance(shielded_battle,
        shielded_monster, definition), 1,
        "equipped life-protection shields raise monster negative resistance")
    strike(ctx, shielded_player, shielded_monster, 2)
    local shielded_drain = ctx:get(shielded_monster,
        component.MONSTER_DRAINED)

    harness.truthy(shielded_drain,
        "partially resistant shielded monsters can still be drained")
    harness.equal(shielded_drain.remaining_aut, 125,
        "life protection halves the source drain duration")

    local skipped_player, skipped_monster = fixture(ctx)

    strike(ctx, skipped_player, skipped_monster, 0, 4)
    harness.falsy(ctx:has(skipped_monster, component.MONSTER_ENFEEBLE),
        "the four-in-five failed chance leaves the target unchanged")
end

return test
