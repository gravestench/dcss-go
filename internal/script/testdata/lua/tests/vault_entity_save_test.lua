-- Live authored monster coexists with its corpse.

local component = require("constants.component")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local item_ids = require("ids.items")
local save = require("policy.save.vault_entities")
local death = require("policy.death")
local catalog = require("policy.catalog")
local origin_policy = require("policy.population.origin")
local origin_schema = require("schemas.vault_origin")

local test = {}

-- One authored orc occurrence is reused across live, corpse, and gear checks.
local function source_record()
    return {
        kind = effects.MONSTER,
        source_id = "saved_fixture",
        identity = "rat",
        x = 10,
        y = 9,
        pending = false,
        arguments = {
            kind_id = monsters.MONS_RAT,
            no_spawn = false,
        },
    }
end

-- Restore validation compares ECS origins against these parsed vault records.
local function level_input()
    local orc = source_record()

    orc.identity = "orc"
    orc.x = 13
    orc.arguments.kind_id = monsters.MONS_ORC

    local item = {
        kind = effects.ITEM,
        source_id = "saved_fixture",
        identity = "corpse",
        x = 16,
        y = 9,
        pending = false,
        arguments = {
            kind_id = item_ids.CORPSE_BODY,
            base_id = monsters.MONS_HUMAN,
        },
    }

    return {
        levels = {
            {
                id = 1,
                vault_id = "saved_fixture",
                vault_records = { source_record(), orc, item },
            },
        },
    }
end

-- Use one authored occurrence key when comparing a live actor with its later corpse.
local function origin_fields()
    return {
        level_id = 1,
        vault_id = "saved_fixture",
        record_index = 1,
        occurrence = 1,
        spawn_x = 10,
        spawn_y = 9,
        kind_id = monsters.MONS_RAT,
    }
end

-- Restore must accept moved origins and corpses, then reject duplicate live occurrences.
function test.run(ctx)
    harness.equal(origin_schema.id, component.VAULT_ORIGIN,
        "test imports production origin schema")

    local rat = ctx:create()

    ctx:add(rat, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })
    ctx:add(rat, component.POSITION, {
        level_id = 1,
        x = 11,
        y = 9,
    })
    ctx:add(rat, component.VAULT_ORIGIN, origin_fields())
    save.validate_vault_entities(ctx, level_input())

    local helper_level = level_input()

    helper_level.levels[1].vault_id = "primary_fixture"
    save.validate_vault_entities(ctx, helper_level)

    local orc_origin = origin_fields()

    orc_origin.record_index = 2
    orc_origin.kind_id = monsters.MONS_ORC
    orc_origin.spawn_x = 13

    -- Death preserves the authored occurrence on the corpse after the actor
    -- disappears, allowing a legitimate restore.
    local corpse = death.corpse(ctx,
        catalog.get("monsters", monsters.MONS_ORC), {
            level_id = 1,
            x = 13,
            y = 9,
        }, orc_origin)

    harness.truthy(corpse, "authored orc left no corpse")
    harness.equal(ctx:get(corpse, component.VAULT_ORIGIN).occurrence,
        origin_policy.CORPSE_OCCURRENCE,
        "corpse lost its authored monster origin")

    -- The same occurrence cannot be both a live monster and its corpse.
    local impossible_orc = ctx:create()

    ctx:add(impossible_orc, component.ACTOR, {
        kind_id = monsters.MONS_ORC,
        speed = 10,
    })
    ctx:add(impossible_orc, component.VAULT_ORIGIN, orc_origin)

    local alive_and_dead = pcall(save.validate_vault_entities, ctx, level_input())

    harness.falsy(alive_and_dead, "live authored monster coexists with its corpse")
    ctx:destroy(impossible_orc)

    local item_origin = origin_fields()

    item_origin.record_index = 3
    item_origin.kind_id = item_ids.CORPSE_SKELETON
    item_origin.spawn_x = 16

    local decayed = ctx:create()

    ctx:add(decayed, component.ITEM, {
        kind_id = item_ids.CORPSE_SKELETON,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(decayed, component.CORPSE, {
        monster_id = monsters.MONS_HUMAN,
        freshness = 110,
        appearance = 1,
    })
    ctx:add(decayed, component.VAULT_ORIGIN, item_origin)

    save.validate_vault_entities(ctx, level_input())

    -- A decayed corpse still must match the source monster species.
    local forged_species = ctx:get(decayed, component.CORPSE)

    forged_species.monster_id = monsters.MONS_ORC
    ctx:set(decayed, component.CORPSE, forged_species)

    local decay_ok = pcall(save.validate_vault_entities, ctx, level_input())

    harness.falsy(decay_ok, "forged decayed corpse species was accepted")
    ctx:destroy(decayed)

    -- Secondary vault gear must match an item occurrence from the source.
    local gear_input = level_input()

    gear_input.levels[1].vault_records[1].arguments.gear_2_kind_id =
        item_ids.MI_STONE

    local gear = ctx:create()
    local gear_origin = origin_fields()

    gear_origin.kind_id = item_ids.MI_STONE
    gear_origin.occurrence = 2
    ctx:add(gear, component.ITEM, {
        kind_id = item_ids.MI_STONE,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(gear, component.VAULT_ORIGIN, gear_origin)
    save.validate_vault_entities(ctx, gear_input)

    gear_input.levels[1].vault_records[1].arguments.gear_2_kind_id =
        item_ids.WPN_DAGGER

    local gear_ok = pcall(save.validate_vault_entities, ctx, gear_input)

    harness.falsy(gear_ok, "forged secondary vault gear was accepted")
    ctx:destroy(gear)

    ctx:add(rat, component.VAULT_ACTOR_OVERRIDES, {
        base_id = "",
        variant = "",
        colour = "red",
        attitude = "hostile",
        spells = {},
    })

    local override_ok = pcall(save.validate_vault_entities, ctx, level_input())

    harness.falsy(override_ok, "forged vault actor override was accepted")
    ctx:remove(rat, component.VAULT_ACTOR_OVERRIDES)

    -- Duplicate origin occurrence IDs are rejected even on separate entities.
    local second = ctx:create()

    ctx:add(second, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })
    ctx:add(second, component.POSITION, {
        level_id = 1,
        x = 12,
        y = 9,
    })
    ctx:add(second, component.VAULT_ORIGIN, origin_fields())

    local ok, reason = pcall(save.validate_vault_entities, ctx, level_input())

    harness.falsy(ok, "duplicate vault occurrence was accepted")
    harness.truthy(reason:find("duplicate", 1, true),
        "duplicate origin error lacks rule")
end

return test
