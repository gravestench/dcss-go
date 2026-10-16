local component = require("constants.component")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local factory = require("policy.population.factory")
local harness = require("tests.harness")
local items = require("ids.items")
local monsters = require("ids.monsters")
local targets = require("policy.ai.targets")
local spell = require("policy.ai.spell")
local vault_items = require("policy.population.vault_items")
local vault_spells = require("constants.vault_spell_override")
local quality = require("constants.vault_item_quality")
local weapon_brands = require("constants.weapon_brands")
local terrain = require("constants.terrain")

local test = {}

local origin = {
    level_id = 1,
    vault_id = "factory_fixture",
    record_index = 3,
    occurrence = 1,
    spawn_x = 12,
    spawn_y = 9,
}

local function world_context(ctx)
    local grid = setmetatable({}, { __index = ctx })

    function grid:random(_, bound)
        harness.truthy(bound > 0, "invalid random bound")

        return 0
    end

    function grid:walkable()
        return true
    end

    function grid:actor_at()
        return nil
    end

    function grid:cell()
        return self.habitat_cell or terrain.DNGN_FLOOR
    end

    function grid:set_cell(_, _, _, feature)
        self.habitat_cell = feature
    end

    function grid:place_actor(entity, level_id, x, y)
        ctx:add(entity, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    return grid
end

local function spawned_actor_has_source_state(ctx)
    local world = world_context(ctx)
    local actor = factory.spawn(world, monsters.MONS_HUMAN, 1, 12, 9, {
        origin = origin,
        colour = "yellow",
        attitude = "neutral",
        spells = { vault_spells.EMPTY_BOOK },
    })
    local identity = ctx:get(actor, component.ACTOR)
    local source = ctx:get(actor, component.VAULT_ORIGIN)
    local overrides = ctx:get(actor, component.VAULT_ACTOR_OVERRIDES)

    harness.equal(identity.kind_id, monsters.MONS_HUMAN,
        "vault monster bypasses ordinary roster")
    harness.equal(identity.speed,
        catalog.get(categories.MONSTERS, monsters.MONS_HUMAN).speed,
        "source monster speed")
    harness.truthy(ctx:get(actor, component.MONSTER_ENERGY).points > 0,
        "monster energy initialized")
    harness.equal(source.vault_id, origin.vault_id, "vault origin ID")
    harness.equal(source.record_index, origin.record_index,
        "vault record index")
    harness.equal(overrides.colour, "yellow", "source colour")
    harness.equal(overrides.attitude, "neutral", "source attitude")
    harness.equal(overrides.spells[1], vault_spells.EMPTY_BOOK,
        "explicit empty spellbook")

    local player = ctx:create()
    local combat = setmetatable({}, { __index = ctx })

    function combat:player()
        return player
    end

    harness.falsy(targets.enemy(combat, actor, player),
        "neutral vault monster attacks the player")

    local mage = factory.spawn(world, monsters.MONS_ORC_WIZARD, 1, 14, 9, {
        origin = origin,
        spells = { vault_spells.EMPTY_BOOK },
    })

    harness.falsy(spell.choose(combat, mage, {
        x = 14,
        y = 9,
    }, {
        x = 15,
        y = 9,
    }), "authored empty spellbook still casts")
end

local function vault_items_keep_variant_and_quantity(ctx)
    local world = world_context(ctx)
    local stones = vault_items.create(world, {
        kind_id = items.MI_STONE,
        quantity = 4,
    }, 1, 16, 9, origin)
    local skeleton = vault_items.create(world, {
        kind_id = items.CORPSE_SKELETON,
        base_id = monsters.MONS_HUMAN,
        variant = "skeleton",
        quantity = 1,
    }, 1, 17, 9, origin)

    harness.equal(ctx:get(stones, component.ITEM).quantity, 4,
        "authored stack quantity")
    harness.equal(ctx:get(stones, component.VAULT_ORIGIN).vault_id,
        origin.vault_id, "item origin")
    harness.equal(ctx:get(skeleton, "core.corpse").monster_id,
        monsters.MONS_HUMAN, "skeleton species")

    local gold = vault_items.create(world, {
        kind_id = items.OBJ_GOLD,
        request = "random_gold",
        generation_depth = 1,
    }, 1, 18, 9, origin)

    harness.equal(ctx:get(gold, component.ITEM).quantity, 1,
        "D:1 source gold quantity at zero draws")

    local exact_gold = vault_items.create(world, {
        kind_id = items.OBJ_GOLD,
        request = "random_gold",
        quantity = 17,
    }, 1, 18, 10, origin)
    local good_weapon = vault_items.create(world, {
        kind_id = items.WPN_DAGGER,
        request = "good_item",
        quality = quality.GOOD,
        allow_uniques = false,
    }, 1, 19, 10, origin)
    local superb_armour = vault_items.create(world, {
        kind_id = items.ARM_ROBE,
        request = "superb_item",
        quality = quality.SUPERB,
        allow_uniques = false,
    }, 1, 20, 10, origin)
    local wand = vault_items.create(world, {
        kind_id = items.WAND_FLAME,
        request = "random_item",
    }, 1, 21, 10, origin)

    harness.equal(ctx:get(exact_gold, component.ITEM).quantity, 17,
        "explicit gold quantity overrides random source quantity")
    harness.equal(ctx:get(good_weapon, component.ITEM).ego,
        weapon_brands.VENOM, "good source weapon uses brand table")
    harness.equal(ctx:get(superb_armour, component.ITEM).plus, 0,
        "source good armour may have zero enchantment")
    harness.equal(ctx:get(wand, component.ITEM).charges, 1,
        "source wand has usable charges")
end

local function source_gear_and_explicit_equipment(ctx)
    local world = world_context(ctx)
    local edmund = factory.spawn(world, monsters.MONS_EDMUND, 1, 18, 9, {
        origin = origin,
    })
    local goblin = factory.spawn(world, monsters.MONS_GOBLIN, 1, 19, 9, {
        origin = origin,
        equipment = {
            { "stone" },
        },
    })
    local edmund_items = 0
    local goblin_items = 0

    for _, entity in ipairs(ctx:query({ component.CARRIED_BY })) do
        local carried = ctx:get(entity, component.CARRIED_BY)

        if carried.holder == edmund then
            edmund_items = edmund_items + 1
        elseif carried.holder == goblin then
            goblin_items = goblin_items + 1
            harness.equal(ctx:get(entity, component.ITEM).kind_id,
                items.MI_STONE, "explicit source item")
        end
    end

    harness.truthy(edmund_items > 0, "content-owned monster gear")
    harness.equal(goblin_items, 1, "explicit equipment replaces generated gear")
end

local function undead_uses_source_species(ctx)
    local world = world_context(ctx)
    local entity = factory.spawn(world, monsters.MONS_SKELETON, 1, 20, 9, {
        origin = origin,
        base_id = monsters.MONS_HUMAN,
        variant = "skeleton",
    })

    harness.truthy(ctx:get(entity, component.HEALTH).max > 0,
        "undead has source species HP")
    harness.equal(ctx:get(entity, component.VAULT_ACTOR_OVERRIDES).base_id,
        monsters.MONS_HUMAN, "undead species retained")
end

local function water_monster_prepares_habitat(ctx)
    local world = world_context(ctx)

    factory.spawn(world, monsters.MONS_ELECTRIC_EEL, 1, 22, 9, {
        origin = origin,
    })

    harness.equal(world.habitat_cell, terrain.DNGN_DEEP_WATER,
        "water monster did not prepare its authored cell")
end

local function failed_placement_is_atomic(ctx)
    local world = world_context(ctx)
    local before = #ctx:query({ component.ACTOR })

    function world:walkable()
        return false
    end

    local ok = pcall(factory.spawn, world, monsters.MONS_GOBLIN,
        1, 11, 9, { origin = origin })

    harness.falsy(ok, "unwalkable vault monster was placed")
    harness.equal(#ctx:query({ component.ACTOR }), before,
        "failed placement left a partial actor")

    function world:walkable()
        return true
    end

    ok = pcall(factory.spawn, world, monsters.MONS_GOBLIN,
        1, 11, 9, {
            origin = origin,
            equipment = {
                { "stone" },
                { "missing source item" },
            },
        })

    harness.falsy(ok, "invalid source equipment was accepted")
    harness.equal(#ctx:query({ component.ACTOR }), before,
        "invalid equipment left a partial actor")
end

function test.run(ctx)
    spawned_actor_has_source_state(ctx)
    vault_items_keep_variant_and_quantity(ctx)
    source_gear_and_explicit_equipment(ctx)
    undead_uses_source_species(ctx)
    water_monster_prepares_habitat(ctx)
    failed_placement_is_atomic(ctx)
end

return test
