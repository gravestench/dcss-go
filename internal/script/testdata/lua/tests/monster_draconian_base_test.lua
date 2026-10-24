-- Classed draconians keep a colored base independently of their job. The
-- production factory, polymorph owner, and corpse policy share that state.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local death = require("policy.death")
local draconian_base = require("policy.monsters.draconian_base")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local factory = require("policy.population.factory")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local save_corpses = require("policy.save.corpses")
local save_monsters = require("policy.save.monsters")
local scenarios = require("constants.scenarios")
local branches = require("ids.branches")
local shapeshifter = require("policy.monsters.shapeshifter")
local vault_effects = require("constants.vault_effects")
local vault_save = require("policy.save.vault_entities")

local test = {}

-- Use the production actor factory and persisted ECS schemas. The fixed
-- draws isolate color identity from combat, gear, and corpse chance.
local function world(ctx)
    local game = fixture.observed_context(ctx)

    game.random = function()
        return 0
    end

    return game
end

-- An ordinary knight gets the source default black base. Its corpse keeps
-- the job as original class while showing black draconian as the species.
local function default_base(ctx, game)
    local knight = factory.spawn(game,
        monsters.MONS_DRACONIAN_KNIGHT, 1, 20, 20)
    local base = ctx:get(knight, component.MONSTER_DRACONIAN_BASE)

    harness.equal(base.base_id, monsters.MONS_BLACK_DRACONIAN,
        "ordinary draconian knight has source default color")
    draconian_base.validate_actor(game, knight)

    -- Restore rejects a living job whose mutable color no longer agrees
    -- with the source default or authored override.
    base.base_id = monsters.MONS_RED_DRACONIAN
    ctx:set(knight, component.MONSTER_DRACONIAN_BASE, base)
    harness.falsy(pcall(draconian_base.validate_actor, game, knight),
        "changed live color cannot pass save validation")
    base.base_id = monsters.MONS_BLACK_DRACONIAN
    ctx:set(knight, component.MONSTER_DRACONIAN_BASE, base)

    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_DRACONIAN_KNIGHT)
    local position = ctx:get(knight, component.POSITION)
    local corpse = death.corpse(game, definition, position, nil, knight)
    local body = ctx:get(corpse, component.CORPSE)

    harness.equal(body.monster_id, monsters.MONS_BLACK_DRACONIAN,
        "unpolymorphed job has colored corpse species")
    harness.equal(body.original_monster_id,
        monsters.MONS_DRACONIAN_KNIGHT,
        "unpolymorphed corpse keeps its job class")

    return corpse
end

-- DES can choose a base other than the job's default. The live actor owns
-- that choice instead of relying on the vault record after it moves.
local function authored_base(ctx, game)
    local knight = factory.spawn(game,
        monsters.MONS_DRACONIAN_KNIGHT, 1, 21, 20, {
            base_id = monsters.MONS_RED_DRACONIAN,
        })
    local base = ctx:get(knight, component.MONSTER_DRACONIAN_BASE)

    harness.equal(base.base_id, monsters.MONS_RED_DRACONIAN,
        "authored base color survives placement")
    draconian_base.validate_actor(game, knight)
    harness.equal(draconian_base.profile_kind(
        monsters.MONS_DRACONIAN_KNIGHT,
        monsters.MONS_RED_DRACONIAN),
        monsters.MONS_DRACONIAN_KNIGHT,
        "save HP profile uses the job instead of its color")

    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_DRACONIAN_KNIGHT)
    local rat = catalog.get(categories.MONSTERS, monsters.MONS_RAT)

    polymorph.fixed(game, knight, rat)

    local form = ctx:get(knight, component.MONSTER_POLYMORPH)

    harness.equal(form.original_kind_id,
        monsters.MONS_DRACONIAN_KNIGHT,
        "roster lineage remains the source job")
    harness.equal(form.corpse_kind_id, monsters.MONS_RED_DRACONIAN,
        "first polymorph retains the colored original")
    harness.falsy(ctx:has(knight, component.MONSTER_DRACONIAN_BASE),
        "temporary rat body has no draconian color")
    draconian_base.validate_actor(game, knight)

    -- A later Chaos shifter mark must not overwrite the first colored
    -- corpse class already recorded by Polymorph.
    shapeshifter.mark(game, knight,
        monsters.MONS_GLOWING_SHAPESHIFTER)

    local shape = ctx:get(knight, component.MONSTER_SHAPESHIFTER)

    harness.equal(shape.corpse_kind_id, monsters.MONS_RED_DRACONIAN,
        "later shifter mark preserves first draconian color")

    local position = ctx:get(knight, component.POSITION)
    local origin = {
        level_id = 1,
        vault_id = "colored_draconian_fixture",
        kind_id = monsters.MONS_DRACONIAN_KNIGHT,
        record_index = 1,
        occurrence = 1,
        spawn_x = position.x,
        spawn_y = position.y,
    }
    local corpse = death.corpse(game, rat, position, origin, knight)
    local body = ctx:get(corpse, component.CORPSE)

    harness.equal(body.monster_id, monsters.MONS_RED_DRACONIAN,
        "polymorphed job yields original colored species")
    harness.equal(body.original_monster_id,
        monsters.MONS_RED_DRACONIAN,
        "polymorphed job records the color as original class")

    -- The authored record chose red, so its saved corpse may identify red
    -- even though the source monster class was a draconian knight.
    vault_save.validate_vault_entities(game, {
        levels = {
            {
                id = 1,
                vault_id = origin.vault_id,
                vault_records = {
                    {
                        kind = vault_effects.MONSTER,
                        source_id = origin.vault_id,
                        identity = "red draconian knight",
                        x = position.x,
                        y = position.y,
                        pending = false,
                        arguments = {
                            kind_id = monsters.MONS_DRACONIAN_KNIGHT,
                            base_id = monsters.MONS_RED_DRACONIAN,
                        },
                    },
                },
            },
        },
    })
end

-- A newly borrowed draconian job gets its own color, but the original rat
-- still decides the corpse when the borrowed body dies.
local function borrowed_job(ctx, game)
    local rat = factory.spawn(game, monsters.MONS_RAT, 1, 22, 20)
    local knight = catalog.get(categories.MONSTERS,
        monsters.MONS_DRACONIAN_KNIGHT)

    polymorph.fixed(game, rat, knight)

    local base = ctx:get(rat, component.MONSTER_DRACONIAN_BASE)

    harness.equal(base.base_id, monsters.MONS_BLACK_DRACONIAN,
        "borrowed job receives its own colored base")
    draconian_base.validate_actor(game, rat)

    local position = ctx:get(rat, component.POSITION)
    local corpse = death.corpse(game, knight, position, nil, rat)
    local body = ctx:get(corpse, component.CORPSE)

    harness.equal(body.monster_id, monsters.MONS_RAT,
        "first source class wins over borrowed draconian color")
end

-- A real save policy checks the same corpse records as the game loader.
function test.run(ctx)
    local game = world(ctx)

    local ambient_corpse = default_base(ctx, game)

    -- Validate the full monster save policy while the ordinary Knight is
    -- still the only live monster. Zot admits its class in the source roster.
    save_monsters.run(game, {
        scenario_id = scenarios.GENERATED_DUNGEON_BASIC,
        current_aut = 0,
        player_alive = true,
        levels = {
            {
                id = 1,
                branch_id = branches.BRANCH_ZOT,
                initial_actors = 100,
            },
        },
    })
    authored_base(ctx, game)
    local saved_corpse = ctx:get(ambient_corpse, component.CORPSE)

    -- A saved ambient job cannot claim a different colored species. Only
    -- an authored vault record may select a color beyond the job default.
    saved_corpse.monster_id = monsters.MONS_RED_DRACONIAN
    ctx:set(ambient_corpse, component.CORPSE, saved_corpse)
    harness.falsy(pcall(save_corpses.run, game, {
        scenario_id = scenarios.GENERATED_DUNGEON_BASIC,
        current_aut = 0,
        levels = {
            {
                id = 1,
                branch_id = branches.BRANCH_ZOT,
            },
        },
    }), "ambient job corpse cannot invent an authored color")
    saved_corpse.monster_id = monsters.MONS_BLACK_DRACONIAN
    ctx:set(ambient_corpse, component.CORPSE, saved_corpse)
    save_corpses.run(game, {
        scenario_id = scenarios.GENERATED_DUNGEON_BASIC,
        current_aut = 0,
        levels = {
            {
                id = 1,
                branch_id = branches.BRANCH_ZOT,
            },
        },
    })
    borrowed_job(ctx, game)
end

return test
