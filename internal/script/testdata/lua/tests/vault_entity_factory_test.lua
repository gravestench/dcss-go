-- Vault entity creation rejects an invalid source equipment definition.

local component = require("constants.component")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local factory = require("policy.population.factory")
local harness = require("tests.harness")
local items = require("ids.items")
local monsters = require("ids.monsters")
local species = require("ids.species")
local jobs = require("ids.jobs")
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
local monster_stats = require("policy.combat.monster_stats")
local presentation = require("policy.presentation.view")
local permanent = require("constants.vault_monster_enchantments")
local attitudes = require("constants.attitude")
local behaviors = require("constants.ai_behaviors")
local vault_enchantments = require("policy.monsters.vault_enchantments")
local paralysis = require("policy.magic.effects.zaps.paralysis")
local confusion = require("policy.magic.effects.statuses.confusing_touch")
local hex_status = require("policy.combat.monster_hexes.status")
local monster_enchant = require("policy.combat.monster_enchant")
local monster_slow = require("policy.combat.monster_slow")
local mute_system = require("systems.zap_monster_mute")
local monster_health = require("policy.combat.monster_health")
local wander = require("policy.ai.wander")
local noise = require("policy.world.noise")
local decision = require("systems.monster_decision")
local item_requests = require("constants.vault_item_requests")

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

-- A DES hp:/hd: pair changes the live actor, rather than merely decorating
-- its saved vault record. Use a rat so HP 12 exceeds its ordinary profile.
local function fixed_source_vitals(ctx)
    local world = world_context(ctx)
    local actor = factory.spawn(world, monsters.MONS_RAT, 1, 35, 10, {
        origin = origin,
        hp = 12,
        hd = 3,
    })
    local overrides = ctx:get(actor, component.VAULT_ACTOR_OVERRIDES)

    harness.equal(ctx:get(actor, component.HEALTH).max, 12,
        "source fixed hit points")
    harness.equal(overrides.fixed_hp, 12, "fixed HP saved on actor")
    harness.equal(overrides.hit_dice, 3, "source HD saved on actor")
    harness.equal(monster_stats.base_hit_dice(world, actor,
        catalog.get(categories.MONSTERS, monsters.MONS_RAT)), 3,
        "combat reads authored hit dice")
end

-- Source name: plus name_adjective changes every presentation of the actor,
-- while dbname: remains a database alias and tile: remains art metadata.
local function authored_actor_identity(ctx)
    local world = world_context(ctx)
    local actor = factory.spawn(world, monsters.MONS_RAT, 1, 36, 10, {
        origin = origin,
        custom_name = "charred",
        name_adjective = true,
        database_name = "vehumet rat",
        tile = "mons_statue_mage",
    })
    local overrides = ctx:get(actor, component.VAULT_ACTOR_OVERRIDES)
    local presented = presentation.entity(world, {
        role = "monster",
        kind_id = monsters.MONS_RAT,
        monster_entity_id = ctx:id(actor),
    })

    harness.equal(display.name(world, actor), "charred rat",
        "messages use the authored adjective")
    harness.equal(presented.name, "charred rat",
        "terminal presentation uses the authored adjective")
    harness.equal(overrides.database_name, "vehumet rat",
        "database alias stays with actor")
    harness.equal(overrides.tile, "mons_statue_mage",
        "tile hint stays with actor")
end

-- Permanent DES enchantments use the live status components, but their
-- source duration must survive the ordinary ten-AUT status tick.
local function permanent_source_enchantments(ctx)
    local world = world_context(ctx)
    local actor = factory.spawn(world, monsters.MONS_RAT, 1, 38, 10, {
        origin = origin,
        permanent_enchantments = {
            permanent.BLIND,
            permanent.CONFUSION,
            permanent.CORONA,
            permanent.DUMB,
            permanent.MAD,
            permanent.MUTE,
            permanent.PARALYSIS,
            permanent.SLOW,
        },
    })
    local speed = ctx:get(actor, component.ACTOR).speed

    harness.truthy(ctx:has(actor, component.PARALYSIS),
        "permanent paralysis affects the actor")
    harness.truthy(confusion.active(world, actor),
        "permanent madness confuses the actor")
    harness.truthy(hex_status.backlit(world, actor),
        "permanent corona backlights the actor")
    harness.truthy(monster_enchant.blinded(world, actor),
        "permanent blindness affects vision")
    harness.truthy(ctx:has(actor, component.MONSTER_MUTE),
        "permanent mute affects spellcasting")
    harness.truthy(speed < catalog.get(categories.MONSTERS,
        monsters.MONS_RAT).speed, "permanent slow changes speed")

    paralysis.tick(world, actor)
    confusion.tick(world, actor)
    hex_status.tick(world, actor, 10)
    monster_enchant.tick(world, actor, 10)
    monster_slow.tick(world, actor)
    mute_system.update(world, actor, 10)

    harness.truthy(ctx:has(actor, component.PARALYSIS),
        "permanent paralysis expired")
    harness.truthy(confusion.active(world, actor),
        "permanent confusion expired")
    harness.truthy(hex_status.backlit(world, actor),
        "permanent corona expired")
    harness.truthy(monster_enchant.blinded(world, actor),
        "permanent blindness expired")
    harness.truthy(ctx:has(actor, component.MONSTER_MUTE),
        "permanent mute expired")
    harness.equal(ctx:get(actor, component.ACTOR).speed, speed,
        "permanent slow expired")

    monster_enchant.dispel(world, actor,
        catalog.get(categories.MONSTERS, monsters.MONS_RAT))
    harness.falsy(vault_enchantments.active(world, actor, permanent.SLOW),
        "dispel left a stale permanent slow marker")
    harness.falsy(vault_enchantments.active(world, actor, permanent.BLIND),
        "dispel left a stale permanent blind marker")
    harness.falsy(vault_enchantments.active(world, actor, permanent.DUMB),
        "dispel left a stale permanent paralysis marker")
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

-- Snake's any-amulet request must select an amulet after the vault choice
-- has been saved. The matching ring request must not slip into that pool.
local function vault_jewellery_keeps_source_half(ctx)
    local world = world_context(ctx)
    local amulet = vault_items.create(world, {
        kind_id = object_classes.OBJ_RANDOM,
        class_id = object_classes.OBJ_JEWELLERY,
        request = item_requests.ANY_AMULET,
        generation_depth = 16,
    }, 1, 51, 9, origin)
    local ring = vault_items.create(world, {
        kind_id = object_classes.OBJ_RANDOM,
        class_id = object_classes.OBJ_JEWELLERY,
        request = item_requests.ANY_RING,
        generation_depth = 16,
    }, 1, 52, 9, origin)

    harness.truthy(ctx:get(amulet, component.ITEM).kind_id:match("^AMU_"),
        "source any amulet produced a ring")
    harness.truthy(ctx:get(ring, component.ITEM).kind_id:match("^RING_"),
        "source any ring produced an amulet")
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

-- Source vault monsters sleep until alerted; an explicit awake flag or a
-- nonhostile role overrides that start. Patrol anchors belong to the actor.
local function authored_spawn_roles(ctx)
    local world = world_context(ctx)

    -- Give each actor a distinct saved source slot at its placed cell.
    local function spawn(x, options)
        options.origin = {
            level_id = 1,
            vault_id = "spawn_role_fixture",
            record_index = x,
            occurrence = 1,
            spawn_x = x,
            spawn_y = 8,
        }

        return factory.spawn(world, monsters.MONS_RAT, 1, x, 8, options)
    end

    local sleeper = spawn(31, {})
    local awake = spawn(32, { generate_awake = true })
    local neutral = spawn(33, { attitude = attitudes.NEUTRAL })
    local patrol = spawn(34, { patrolling = true })

    harness.equal(ctx:get(sleeper, component.AI).behavior, behaviors.SLEEP,
        "ordinary vault monster starts asleep")
    harness.equal(ctx:get(awake, component.AI).behavior, behaviors.WANDER,
        "generate_awake starts the actor wandering")
    harness.equal(ctx:get(neutral, component.AI).behavior, behaviors.WANDER,
        "nonhostile vault monster starts awake")
    harness.equal(ctx:get(patrol, component.AI).behavior, behaviors.SLEEP,
        "patrolling does not silently imply awake")

    local statue = factory.spawn(world, monsters.MONS_ORANGE_STATUE,
        1, 37, 8, {
            origin = {
                level_id = 1,
                vault_id = "spawn_role_fixture",
                record_index = 37,
                occurrence = 1,
                spawn_x = 37,
                spawn_y = 8,
            },
        })

    harness.equal(ctx:get(statue, component.AI).behavior, behaviors.WANDER,
        "source statues do not start asleep")

    local anchor = ctx:get(patrol, component.MONSTER_PATROL)

    harness.equal(anchor.level_id, 1, "patrol anchor level")
    harness.equal(anchor.x, 34, "patrol anchor x")
    harness.equal(anchor.y, 8, "patrol anchor y")

    -- The regular wandering rule must pick within the patrol area even if
    -- the monster has chased the player far away from its source cell.
    -- The patrol test admits its source cells without requiring a grid map.
    function world:visible()
        return true
    end

    local state = ctx:get(patrol, component.AI)
    local remote = {
        level_id = 1,
        x = 50,
        y = 8,
    }

    state.behavior = behaviors.WANDER
    wander.update(world, patrol, state, remote)
    harness.truthy(math.abs(state.target_x - anchor.x) <= 7 and
        math.abs(state.target_y - anchor.y) <= 7,
        "patrol target drifted beyond its authored anchor")

    monster_health.damage(world, sleeper, 1, world:player())
    harness.falsy(ctx:get(sleeper, component.AI).behavior == behaviors.SLEEP,
        "damage did not wake the authored sleeper")

    local hearer = spawn(35, {})

    local noise_origin = {
        level_id = 1,
        x = 35,
        y = 8,
    }

    noise.emit(world, noise_origin, 1, world:player())
    harness.equal(ctx:get(hearer, component.AI).behavior, behaviors.WANDER,
        "audible noise did not wake the authored sleeper")

    local hidden = spawn(36, {})

    ctx:add(world:player(), component.POSITION, {
        level_id = 1,
        x = 40,
        y = 8,
    })

    -- An unseen player must leave the sleeping actor's AI unchanged.
    function world:visible()
        return false
    end

    decision.update(world, hidden)
    harness.equal(ctx:get(hidden, component.AI).behavior, behaviors.SLEEP,
        "an unseen player woke a sleeping vault actor")
    harness.equal(ctx:get(hidden, component.INTENT).kind, 6,
        "sleeping actor chose an action instead of waiting")

    ctx:add(world:player(), component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(world:player(), component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(world:player(), component.SKILLS, { entries = {} })

    -- This pass exercises the real stealth contest and target-memory path.
    function world:visible()
        return true
    end

    -- The isolated rule test has no running turn scheduler.
    function world:aut()
        return 0
    end

    local seen = spawn(38, {})

    decision.update(world, seen)
    harness.equal(ctx:get(seen, component.AI).behavior, behaviors.SEEK,
        "a sighted player did not wake the sleeper into pursuit")
    harness.truthy(ctx:has(seen, component.INTENT),
        "woken monster produced no decision")
end

-- Exercise factory provenance, source overrides, habitat writes, and atomic
-- failure in one world.
function test.run(ctx)
    spawned_actor_has_source_state(ctx)
    fixed_source_vitals(ctx)
    authored_actor_identity(ctx)
    permanent_source_enchantments(ctx)
    vault_items_keep_variant_and_quantity(ctx)
    vault_jewellery_keeps_source_half(ctx)
    source_gear_and_explicit_equipment(ctx)
    trog_guard_keeps_source_gear(ctx)
    weighted_vault_equipment(ctx)
    undead_uses_source_species(ctx)
    water_monster_prepares_habitat(ctx)
    failed_placement_is_atomic(ctx)
    research_items_materialize(ctx)
    merged_slime_is_one_actor(ctx)
    unique_claim_is_atomic(ctx)
    authored_spawn_roles(ctx)
end

return test
