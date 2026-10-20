-- Vault entity creation rejects an invalid source equipment definition.

local component = require("constants.component")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local factory = require("policy.population.factory")
local harness = require("tests.harness")
local items = require("ids.items")
local monsters = require("ids.monsters")
local object_classes = require("ids.object_classes")
local targets = require("policy.ai.targets")
local spell = require("policy.ai.spell")
local vault_items = require("policy.population.vault_items")
local vault_spells = require("constants.vault_spell_override")
local quality = require("constants.vault_item_quality")
local schools = require("constants.spell_schools")
local weapon_brands = require("constants.weapon_brands")
local gods = require("constants.gods")
local terrain = require("constants.terrain")
local hit_points = require("policy.population.hit_points")
local slime_blob = require("policy.monsters.slime_blob")
local display = require("policy.combat.monster_support.display")

local test = {}

local origin = {
    level_id = 1,
    vault_id = "factory_fixture",
    record_index = 3,
    occurrence = 1,
    spawn_x = 12,
    spawn_y = 9,
}

-- The world proxy gives vault materialization a deterministic random stream
-- while retaining real ECS components and placement calls.
local function world_context(ctx)
    local grid = setmetatable({}, { __index = ctx })
    local player = ctx:create()

    -- Real unique placement records its claim on the run owner. Keep the
    -- fixture's player minimal while using the production component schema.
    ctx:add(player, component.PLAYER_UNIQUE_HISTORY, {
        status = {},
        monsters = {},
        pan_states = {},
        boris_killed = false,
    })

    function grid:player()
        return player
    end

    -- Force the first weighted choice while still catching invalid random bounds.
    function grid:random(_, bound)
        harness.truthy(bound > 0, "invalid random bound")

        return 0
    end

    -- Keep fixture cells open so later assertions isolate actor and equipment rules.
    function grid:walkable()
        return true
    end

    -- An empty world lets the factory create each test actor without collision.
    function grid:actor_at()
        return nil
    end

    -- Read the mutable habitat cell to verify water-monster preparation.
    function grid:cell()
        return self.habitat_cell or terrain.DNGN_FLOOR
    end

    -- Record terrain writes so the eel's deep-water conversion can be asserted.
    function grid:set_cell(_, _, _, feature)
        self.habitat_cell = feature
    end

    -- Mirror the world placement call into real ECS position data.
    function grid:place_actor(entity, level_id, x, y)
        ctx:add(entity, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    return grid
end

-- A vault actor keeps source color, attitude, spellbook, and origin fields.
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

    -- Return the fixture player so neutrality and spell targeting use the real target predicate.
    function combat:player()
        return player
    end

    harness.falsy(targets.enemy(combat, actor, player),
        "neutral vault monster attacks the player")

    local mage = factory.spawn(world, monsters.MONS_ORC_WIZARD, 1, 14, 9, {
        origin = origin,
        spells = { vault_spells.EMPTY_BOOK },
    })

    harness.falsy(spell.choose(combat, mage, player, false),
        "authored empty spellbook still casts")
end

-- Authored item modifiers survive through entity creation and stacking.
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

-- Explicit vault equipment overrides ordinary monster gear generation.
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

-- A Trog guard's authored faith and identified antimagic spear must reach
-- ECS components rather than being discarded after parsing its DES text.
local function trog_guard_keeps_source_gear(ctx)
    local world = world_context(ctx)
    local guard = factory.spawn(world, monsters.MONS_ORC, 5, 29, 10, {
        origin = origin,
        god_id = gods.TROG,
        equipment = {
            { "spear ego:antimagic ident:type" },
        },
    })
    local overrides = ctx:get(guard, component.VAULT_ACTOR_OVERRIDES)
    local spear

    harness.equal(overrides.god_id, gods.TROG,
        "authored monster god survives on the actor")

    for _, entity in ipairs(ctx:query({ component.CARRIED_BY })) do
        if ctx:get(entity, component.CARRIED_BY).holder == guard then
            spear = entity
            break
        end
    end

    harness.truthy(spear, "Trog guard receives its authored spear")
    harness.equal(ctx:get(spear, component.ITEM).ego,
        weapon_brands.ANTIMAGIC, "authored weapon brand survives")
    harness.truthy(ctx:get(spear, component.ITEM_IDENTIFICATION).known_type,
        "source ident:type survives on the item")
end

-- Equipment alternatives use their item weights before the winner is
-- resolved. A generic source weapon must also become a concrete item.
local function weighted_vault_equipment(ctx)
    local world = world_context(ctx)
    local bounds = {}

    function world:random(stream, bound)
        if stream == "vault_equipment" then
            bounds[#bounds + 1] = bound

            return bound - 1
        end

        return 0
    end

    local guard = factory.spawn(world, monsters.MONS_ORC, 5, 30, 10, {
        origin = origin,
        equipment = {
            { "spear w:3", "club w:5" },
        },
    })
    local chosen

    for _, entity in ipairs(ctx:query({ component.CARRIED_BY })) do
        if ctx:get(entity, component.CARRIED_BY).holder == guard then
            chosen = ctx:get(entity, component.ITEM).kind_id
            break
        end
    end

    harness.equal(bounds[1], 3, "first equipment weight sets the bound")
    harness.equal(bounds[2], 8, "weights accumulate across alternatives")
    harness.equal(chosen, items.WPN_SPEAR,
        "weighted selection keeps the chosen weapon")

    local generic = factory.spawn(world, monsters.MONS_GOBLIN, 5, 31, 10, {
        origin = origin,
        equipment = {
            { "any weapon" },
        },
    })
    local found = false

    for _, entity in ipairs(ctx:query({ component.CARRIED_BY })) do
        if ctx:get(entity, component.CARRIED_BY).holder == generic then
            local item = ctx:get(entity, component.ITEM)
            local kind = catalog.get(categories.ITEMS, item.kind_id)

            found = kind.class == object_classes.OBJ_WEAPONS
        end
    end

    harness.truthy(found, "any weapon resolves before equipment creation")
end

-- Undead variants retain the source species needed for corpse and save rules.
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

-- Habitat preparation precedes placement of an authored water monster.
local function water_monster_prepares_habitat(ctx)
    local world = world_context(ctx)

    factory.spawn(world, monsters.MONS_ELECTRIC_EEL, 1, 22, 9, {
        origin = origin,
    })

    harness.equal(world.habitat_cell, terrain.DNGN_DEEP_WATER,
        "water monster did not prepare its authored cell")
end

-- A placement error must not leave an actor or partial equipment behind.
local function failed_placement_is_atomic(ctx)
    local world = world_context(ctx)
    local before = #ctx:query({ component.ACTOR })

    -- Reject this spawn before any actor component or equipment can be committed.
    function world:walkable()
        return false
    end

    local ok = pcall(factory.spawn, world, monsters.MONS_GOBLIN,
        1, 11, 9, { origin = origin })

    harness.falsy(ok, "unwalkable vault monster was placed")
    harness.equal(#ctx:query({ component.ACTOR }), before,
        "failed placement left a partial actor")

    -- Reopen the cell to isolate the invalid-equipment rollback path.
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

-- Use the same production vault item factory for the research book and the
-- toxicology room's identified potion. Both fields must survive generation
-- into Akara components, not merely remain in the source record.
local function research_items_materialize(ctx)
    local world = world_context(ctx)
    local book = vault_items.create(world, {
        kind_id = items.BOOK_RANDART_THEME,
        generation_depth = 22,
        disc = schools.FIRE,
        numspells = 5,
    }, 1, 24, 10, origin)
    local spells = ctx:get(book, component.ITEM_RANDOM_BOOK)

    harness.truthy(spells and #spells.spells > 0,
        "research book creates a spell list")
    harness.equal(spells.theme, "fire/fire",
        "research book retains its school")

    local potion = vault_items.create(world, {
        kind_id = items.POT_MUTATION,
        ident = "type",
    }, 1, 25, 10, origin)
    local known = ctx:get(potion, component.ITEM_IDENTIFICATION)

    harness.truthy(known and known.known_type,
        "research potion is type identified")
    harness.falsy(known.known_properties,
        "ident:type does not reveal unrelated properties")
end

-- A named DES slime becomes one ECS actor with source-sized HP, melee
-- damage, and display. These values must agree with Planerend's slime state.
local function merged_slime_is_one_actor(ctx)
    local world = world_context(ctx)
    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_SLIME_CREATURE)
    local base_hp = hit_points.roll(world, definition.average_hp_10x)
    local actor = factory.spawn(world, monsters.MONS_SLIME_CREATURE,
        14, 26, 10, {
            origin = origin,
            blob_size = 3,
        })
    local health = ctx:get(actor, component.HEALTH)

    harness.equal(ctx:get(actor, component.SLIME_BLOB).size, 3,
        "merged slime size belongs to the actor")
    harness.equal(health.max, base_hp * 3,
        "three slime bodies triple their health")
    harness.equal(slime_blob.attack_damage(world, actor, 5), 15,
        "three bodies triple natural melee damage")
    harness.equal(display.name(world, actor),
        "very large slime creature", "display reads live blob size")
end

-- The run ledger must reject a second named monster before allocating
-- another ECS actor, including after the first actor is no longer live.
local function unique_claim_is_atomic(ctx)
    local world = world_context(ctx)

    factory.spawn(world, monsters.MONS_EDMUND, 1, 27, 10, {
        origin = origin,
    })

    local before = #ctx:query({ component.ACTOR })
    local ok = pcall(factory.spawn, world, monsters.MONS_EDMUND,
        1, 28, 10, { origin = origin })

    harness.falsy(ok, "second Edmund should be rejected")
    harness.equal(#ctx:query({ component.ACTOR }), before,
        "rejected unique left no partial actor")
end

-- Exercise factory provenance, source overrides, habitat writes, and atomic
-- failure in one world.
function test.run(ctx)
    spawned_actor_has_source_state(ctx)
    vault_items_keep_variant_and_quantity(ctx)
    source_gear_and_explicit_equipment(ctx)
    trog_guard_keeps_source_gear(ctx)
    weighted_vault_equipment(ctx)
    undead_uses_source_species(ctx)
    water_monster_prepares_habitat(ctx)
    failed_placement_is_atomic(ctx)
    research_items_materialize(ctx)
    merged_slime_is_one_actor(ctx)
    unique_claim_is_atomic(ctx)
end

return test
