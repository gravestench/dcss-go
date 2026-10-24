-- Source _fill_out_corpse distinguishes a dying body's combat kind from
-- its original class and the species written on the corpse item.
local catalog = require("policy.catalog")
local beogh_corpse = require("policy.abilities.beogh.corpse")
local categories = require("constants.catalog")
local component = require("constants.component")
local scenarios = require("constants.scenarios")
local death = require("policy.death")
local effects = require("constants.vault_effects")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local save = require("policy.save.vault_entities")
local save_corpses = require("policy.save.corpses")
local shapeshifter = require("policy.monsters.shapeshifter")

local test = {}

-- A real ECS monster passes through the production corpse policy. The
-- fixture fixes only the corpse coin flip and appearance draw.
local function corpse_for(ctx, body_id, x)
    local monster = fixture.actor(ctx, body_id, x, 62, 15)
    local game = fixture.context(ctx, monster)
    local definition = catalog.get(categories.MONSTERS, body_id)

    game.random = function()
        return 0
    end

    return game, monster, definition
end

-- Polymorph leaves the first species' corpse, even though combat and XP
-- used the temporary quokka body immediately before death.
local function polymorphed_body(ctx)
    local game, monster, body = corpse_for(ctx, monsters.MONS_QUOKKA, 61)

    ctx:add(monster, component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_RAT,
    })

    local position = ctx:get(monster, component.POSITION)
    local corpse = death.corpse(game, body, position, nil, monster)
    local state = ctx:get(corpse, component.CORPSE)

    harness.equal(state.monster_id, monsters.MONS_RAT,
        "polymorphed corpse uses its original species")
    harness.equal(state.original_monster_id, monsters.MONS_RAT,
        "corpse retains its original class")
end

-- Ordinary monster jobs yield their broader species while retaining the
-- exact class for consumers that need the pre-death monster profile.
local function ordinary_class(ctx)
    local game, monster, body = corpse_for(ctx, monsters.MONS_ORC_KNIGHT,
        62)
    local position = ctx:get(monster, component.POSITION)
    local origin = {
        level_id = 1,
        vault_id = "corpse_class_fixture",
        kind_id = monsters.MONS_ORC_KNIGHT,
        record_index = 1,
        occurrence = 1,
        spawn_x = 62,
        spawn_y = 62,
    }
    local corpse = death.corpse(game, body, position, origin, monster)
    local state = ctx:get(corpse, component.CORPSE)

    harness.equal(state.monster_id, monsters.MONS_ORC,
        "orc knight leaves an orc species corpse")
    harness.equal(state.original_monster_id, monsters.MONS_ORC_KNIGHT,
        "corpse retains the precise orc class")

    -- Resurrection uses the exact class while the corpse item stores Orc.
    beogh_corpse.record(game, monster, corpse, {})
    beogh_corpse.validate(game, corpse)

    -- The authored monster's corpse keeps its vault occurrence even though
    -- its corpse species is broader than the source record's exact class.
    local vault = {
        levels = {
            {
                id = 1,
                vault_id = origin.vault_id,
                vault_records = {
                    {
                        kind = effects.MONSTER,
                        source_id = origin.vault_id,
                        identity = "orc knight",
                        x = origin.spawn_x,
                        y = origin.spawn_y,
                        pending = false,
                        arguments = {
                            kind_id = monsters.MONS_ORC_KNIGHT,
                        },
                    },
                },
            },
        },
    }

    save.validate_vault_entities(game, vault)

    -- A source vault Orc Knight cannot claim a shifter corpse without the
    -- accompanying source class recorded at conversion.
    local forged = ctx:get(corpse, component.CORPSE)

    forged.monster_id = monsters.MONS_GLOWING_SHAPESHIFTER
    forged.original_monster_id = monsters.MONS_GLOWING_SHAPESHIFTER
    ctx:set(corpse, component.CORPSE, forged)

    local valid = pcall(save.validate_vault_entities, game, vault)

    harness.falsy(valid, "vault corpse requires shifter source context")
    ctx:destroy(corpse)

    -- A real Chaos conversion records the original vault class, so the
    -- same saved origin is valid after the shifter eventually dies.
    shapeshifter.mark(game, monster,
        monsters.MONS_GLOWING_SHAPESHIFTER)

    local changed = death.corpse(game, body, position, origin, monster)
    local changed_state = ctx:get(changed, component.CORPSE)

    harness.equal(changed_state.shapeshifter_source_id,
        monsters.MONS_ORC_KNIGHT,
        "shifter corpse retains its authored source class")
    save.validate_vault_entities(game, vault)
end

-- A generated roster lists precise classes. Its save validator must admit
-- the corpse species those classes yield after death.
local function generated_roster_class(ctx)
    local game, monster, body = corpse_for(ctx, monsters.MONS_WIZARD, 60)
    local position = ctx:get(monster, component.POSITION)
    local corpse = death.corpse(game, body, position, nil, monster)

    harness.truthy(corpse)
    save_corpses.run(game, {
        scenario_id = scenarios.GENERATED_DUNGEON_BASIC,
        current_aut = 0,
    })
end

-- Source saves a current Orc for Beogh even when the corpse item shows the
-- actor's pre-polymorph species. Both records must survive restore.
local function polymorphed_orc_snapshot(ctx)
    local game, monster, body = corpse_for(ctx, monsters.MONS_ORC_KNIGHT,
        65)

    ctx:add(monster, component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_RAT,
    })

    local position = ctx:get(monster, component.POSITION)
    local corpse = death.corpse(game, body, position, nil, monster)
    local state = ctx:get(corpse, component.CORPSE)

    harness.equal(state.monster_id, monsters.MONS_RAT,
        "corpse species predates the current Orc body")
    harness.equal(state.death_kind_id, monsters.MONS_ORC_KNIGHT,
        "corpse remembers the body Beogh can resurrect")
    beogh_corpse.record(game, monster, corpse, {})
    beogh_corpse.validate(game, corpse)
    save_corpses.run(game, {
        scenario_id = scenarios.GENERATED_DUNGEON_BASIC,
        current_aut = 0,
    })
end

-- A Chaos-marked actor receives ORIGINAL_TYPE_KEY before its first new
-- form. The shifter variant is its corpse class in this order.
local function shapeshifter_variant(ctx)
    local game, monster, body = corpse_for(ctx, monsters.MONS_QUOKKA, 63)

    shapeshifter.mark(game, monster,
        monsters.MONS_GLOWING_SHAPESHIFTER)
    ctx:add(monster, component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_QUOKKA,
    })

    local position = ctx:get(monster, component.POSITION)
    local corpse = death.corpse(game, body, position, nil, monster)
    local state = ctx:get(corpse, component.CORPSE)

    harness.equal(state.monster_id, monsters.MONS_GLOWING_SHAPESHIFTER,
        "borrowed body reveals the permanent shifter species")
    harness.equal(state.original_monster_id,
        monsters.MONS_GLOWING_SHAPESHIFTER,
        "shifter corpse retains its true class")
end

-- Adding the permanent enchantment after an earlier Polymorph cannot
-- replace ORIGINAL_TYPE_KEY. The first transformation's true class wins.
local function already_polymorphed_shifter(ctx)
    local game, monster, body = corpse_for(ctx, monsters.MONS_QUOKKA, 64)

    ctx:add(monster, component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_ORC,
    })

    shapeshifter.mark(game, monster, monsters.MONS_GLOWING_SHAPESHIFTER)

    local position = ctx:get(monster, component.POSITION)
    local corpse = death.corpse(game, body, position, nil, monster)
    local state = ctx:get(corpse, component.CORPSE)

    harness.equal(state.monster_id, monsters.MONS_ORC,
        "an older polymorph origin wins over later shifter status")
    harness.equal(state.original_monster_id, monsters.MONS_ORC,
        "the earlier source class remains on the corpse")
end

-- Keep all cases on the same production ECS schema and catalog.
function test.run(ctx)
    generated_roster_class(ctx)
    polymorphed_body(ctx)
    ordinary_class(ctx)
    polymorphed_orc_snapshot(ctx)
    shapeshifter_variant(ctx)
    already_polymorphed_shifter(ctx)
end

return test
