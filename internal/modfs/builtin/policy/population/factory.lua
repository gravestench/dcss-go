-- Example: A monster assigned an incompatible habitat cell moves to a legal nearby cell.
local catalog = require("policy.catalog")
local items = require("policy.inventory.items")
local gear = require("policy.population.gear")
local hit_points = require("policy.population.hit_points")
local energy = require("policy.monster_energy")
local roster = require("policy.population.roster")
local component = require("constants.component")
local item_specs = require("policy.generation.vaults.specs.item")
local choice = require("policy.generation.vaults.specs.choice")
local resolve = require("policy.generation.vaults.specs.resolve")
local origin_component = require("policy.population.origin")
local habitats = require("constants.monster_habitats")
local terrain = require("constants.terrain")
local monsters = require("ids.monsters")
local object_classes = require("ids.object_classes")
local armour_slots = require("constants.armour_slots")
local weapon_brands = require("constants.weapon_brands")
local armour_egos = require("constants.armour_egos")
local missile_brands = require("constants.missile_brands")
local shapeshifter = require("policy.monsters.shapeshifter")
local unique_history = require("policy.population.unique_history")
local generation = require("policy.item_generation")
local identification = require("policy.items.identification")
local item_purpose = require("constants.item_generation_purpose")
local item_quality = require("constants.vault_item_quality")
local vault_enchantments = require("policy.monsters.vault_enchantments")
local attitudes = require("constants.attitude")
local statues = require("constants.monster_statues")
local behaviors = require("constants.ai_behaviors")
local pan_lord = require("policy.population.pan_lord")
local ugly_thing = require("policy.monsters.ugly_thing")
local cloud_ring = require("policy.combat.monster_cloud_ring")

local factory = {}

-- Source dungeon placement converts an incompatible authored monster cell
-- to its primary habitat before the actor enters the grid.
local function prepare_habitat(ctx, source, level_id, x, y)
    if source.habitat_id ~= habitats.WATER and
        source.habitat_id ~= habitats.LAVA then
        return
    end

    local current = ctx:cell(level_id, x, y)

    if source.habitat_id == habitats.WATER and
        current ~= terrain.DNGN_SHALLOW_WATER and
        current ~= terrain.DNGN_DEEP_WATER then
        ctx:set_cell(level_id, x, y, terrain.DNGN_DEEP_WATER)
    elseif source.habitat_id == habitats.LAVA and
        current ~= terrain.DNGN_LAVA then
        ctx:set_cell(level_id, x, y, terrain.DNGN_LAVA)
    end
end

-- Validate the catalog class before attaching a carried and equipped monster item.
local function starting_item(ctx, holder, kind_id, quantity, plus, ego, slot,
    origin, occurrence)
    local definition = catalog.get("items", kind_id)

    if (slot == "weapon" or slot == "alternate_weapon") and
        definition.class ~= "OBJ_WEAPONS" then
        error("monster starting item is not a weapon: " .. kind_id)
    end

    if slot == "missile" and definition.class ~= "OBJ_MISSILES" then
        error("monster starting item is not ammunition: " .. kind_id)
    end

    local item = {
        kind_id = kind_id,
        quantity = quantity,
        plus = plus,
        charges = 0,
        ego = ego,
    }

    items.validate(item, definition)

    local entity = ctx:create()
    ctx:add(entity, "core.item", item)
    ctx:add(entity, "core.carried_by", { holder = holder })
    ctx:add(entity, "core.equipped", { slot = slot })

    if origin then
        ctx:add(entity, component.VAULT_ORIGIN,
            origin_component.for_entity(origin, kind_id, occurrence))
    end

    return entity
end

-- Create each generated equipment entity after the monster actor exists.
local function create_loadout(ctx, monster, loadout, origin)
    if not loadout then
        return
    end

    local primary = loadout.primary
    starting_item(ctx, monster, primary.kind_id, 1,
        primary.quality.plus, primary.quality.ego, "weapon", origin, 2)

    if loadout.alternate then
        local alternate = loadout.alternate
        starting_item(ctx, monster, alternate.kind_id, 1,
            alternate.quality.plus, alternate.quality.ego,
            "alternate_weapon", origin, 3)
    end

    if loadout.ammunition then
        local ammunition = loadout.ammunition
        starting_item(ctx, monster, ammunition.kind_id,
            ammunition.quantity, 0, ammunition.ego, "missile", origin, 4)
    end
end

-- Parse every source option before drawing so malformed alternatives fail
-- even when this seed would have picked a different item.
local function equipment_choice(ctx, slot, site)
    local alternatives = {}
    local random = {}

    for _, expression in ipairs(slot) do
        alternatives[#alternatives + 1] = item_specs.term(expression, site)
    end

    -- Keep item option weights on their own vault equipment stream.
    function random:roll(bound)
        return ctx:random("vault_equipment", bound)
    end

    return choice.pick(random, alternatives)
end

-- A source "any weapon" requests a class, not a concrete catalog item.
-- Roll it before actor creation, then carry the result into its ECS item.
local function roll_generic_equipment(ctx, resolved, options)
    if resolved.kind_id ~= object_classes.OBJ_RANDOM then
        return nil
    end

    local site = options.site and
        (options.site.path .. ":" .. options.site.line) or
        "vault monster equipment"
    local rolled = generation.roll(ctx, {
        depth = options.depth or 1,
        quality = item_quality.ORDINARY,
        class_id = resolved.class_id,
        allow_uniques = false,
        purpose = item_purpose.VAULT,
        site = site,
    })

    resolved.kind_id = rolled.kind_id

    return rolled
end

-- Translate a source ego name through its item class; item validation then
-- rejects a legal brand that is incompatible with this particular kind.
local function equipment_ego(parsed, definition)
    if not parsed.ego then
        return ""
    end

    local choices

    if definition.class == object_classes.OBJ_WEAPONS then
        choices = weapon_brands
    elseif definition.class == object_classes.OBJ_ARMOUR then
        choices = armour_egos
    elseif definition.class == object_classes.OBJ_MISSILES then
        choices = missile_brands
    end

    local ego = choices and choices[parsed.ego:upper()]

    if not ego then
        error("unknown vault equipment ego " .. parsed.ego)
    end

    return ego
end

-- Resolve one selected equipment term before allocating an actor. This
-- prevents a bad gear spec from leaving a half-created monster in the ECS.
local function equipment_entry(ctx, parsed, options)
    if parsed.no_spawn then
        return nil
    end

    local resolved = resolve.item(ctx, parsed,
        options.depth or 1, options.site)
    local rolled = roll_generic_equipment(ctx, resolved, options)
    local definition = catalog.get("items", resolved.kind_id)
    local ego = equipment_ego(parsed, definition)

    if rolled and parsed.ego then
        rolled.ego = ego
    end

    if rolled and parsed.plus then
        rolled.plus = parsed.plus
    end

    local item = {
        kind_id = resolved.kind_id,
        quantity = rolled and rolled.quantity or resolved.quantity or 1,
        plus = rolled and rolled.plus or parsed.plus or 0,
        charges = rolled and rolled.charges or 0,
        ego = rolled and rolled.ego or ego,
    }

    items.validate(item, definition)

    return {
        item = item,
        class = definition.class,
        ident = parsed.ident,
        rolled = rolled,
    }
end

-- Authored equipment suppresses ordinary monster gear. Resolve each source
-- slot separately so its weights and empty option cannot cross slot bounds.
local function explicit_equipment(ctx, options)
    local selected = {}

    for _, slot in ipairs(options.equipment or {}) do
        local parsed = equipment_choice(ctx, slot, options.site)
        local entry = equipment_entry(ctx, parsed, options)

        if entry then
            selected[#selected + 1] = entry
        end
    end

    return selected
end

-- Give successive source weapon slots to the primary and alternate hands.
-- Body armour and shields use their catalog slots. Any further items that
-- would claim an occupied slot remain carried, preserving authored gear
-- without corrupting the save invariant that each slot has one owner.
local function give_explicit_equipment(ctx, monster, selected, origin)
    local weapons = 0
    local missiles = 0
    local occupied = {}

    for index, entry in ipairs(selected) do
        local entity
        local slot

        if entry.class == object_classes.OBJ_WEAPONS then
            weapons = weapons + 1

            if weapons == 1 then
                slot = "weapon"
            elseif weapons == 2 then
                slot = "alternate_weapon"
            end
        elseif entry.class == object_classes.OBJ_MISSILES then
            missiles = missiles + 1

            if missiles == 1 then
                slot = "missile"
            end
        elseif entry.class == object_classes.OBJ_ARMOUR then
            local definition = catalog.get("items", entry.item.kind_id)
            local source_slot = definition.armour and
                definition.armour.slot_id

            if source_slot == armour_slots.BODY_ARMOUR then
                slot = "body"
            elseif source_slot == armour_slots.SHIELD then
                slot = "shield"
            end
        end

        if occupied[slot] then
            slot = nil
        elseif slot then
            occupied[slot] = true
        end

        if entry.rolled then
            entity = generation.create(ctx, entry.rolled, {
                carrier = monster,
            })
        else
            entity = ctx:create()
            ctx:add(entity, component.ITEM, entry.item)
            ctx:add(entity, component.CARRIED_BY, { holder = monster })
        end

        if entry.ident == "type" or entry.ident == "all" then
            identification.reveal_item(ctx, entity, {
                type = true,
                pluses = entry.ident == "all",
                properties = entry.ident == "all",
            })
        end
        if slot then
            ctx:add(entity, component.EQUIPPED, { slot = slot })
        end

        if origin then
            ctx:add(entity, component.VAULT_ORIGIN,
                origin_component.for_entity(origin, entry.item.kind_id, index + 1))
        end
    end
end

-- Create habitat terrain before placing the monster, then attach loadout and vault origin to new entities.
-- Roll health and construct components only after the target habitat cell is prepared.
function factory.spawn(ctx, kind_id, level_id, x, y, options)
    options = options or {}

    if options.hydra_heads and options.hydra_heads ~= 0 and
        (options.hydra_heads < 1 or options.hydra_heads > 20 or
            options.hydra_heads % 1 ~= 0) then
        error("invalid authored hydra head count " ..
            tostring(options.hydra_heads))
    end

    if options.hp and (options.hp < 1 or options.hp > 10000 or
        options.hp % 1 ~= 0) then
        error("invalid authored monster HP " .. tostring(options.hp))
    end

    if options.hd and (options.hd < 1 or options.hd > 100 or
        options.hd % 1 ~= 0) then
        error("invalid authored monster HD " .. tostring(options.hd))
    end

    vault_enchantments.validate(options.permanent_enchantments)

    local definition = catalog.get("monsters", kind_id)
    local source = definition

    if options.base_id then
        source = catalog.get("monsters", options.base_id)

        -- Source colour+role draconians keep the role's HD and HP while
        -- their saved base ID identifies the colour for additive traits.
        if definition.genus_id == monsters.MONS_DRACONIAN and
            source.genus_id == monsters.MONS_DRACONIAN and
            definition.id ~= source.id then
            source = definition
        end
    end

    if not source.average_hp_10x or source.average_hp_10x <= 0 then
        error("vault monster has no spawn profile " .. kind_id)
    end

    -- Check run history before creating gear or an actor. A failed unique
    -- attempt must not leave entities behind or consume another claim.
    if not options.restore_identity and
        unique_history.is_unique(kind_id) and
        unique_history.seen(ctx, kind_id) then
        error("unique monster was already generated " .. kind_id)
    end

    if not ctx:walkable(level_id, x, y) or ctx:actor_at(level_id, x, y) then
        error("cannot place monster " .. kind_id)
    end

    local profile = roster.profile(source.id)
    local generated_lord
    local generated_ugly

    if kind_id == monsters.MONS_PANDEMONIUM_LORD then
        generated_lord = pan_lord.roll(ctx,
            options.attitude == attitudes.FRIENDLY)
    end

    if ugly_thing.kind(kind_id) then
        generated_ugly = ugly_thing.roll(ctx, definition,
            options.colour)
    end

    local hp = options.hp or
        (generated_lord and generated_lord.hp) or
        hit_points.roll(ctx, source.average_hp_10x)
    local blob_size = options.blob_size or 1

    if blob_size ~= 1 and
        (kind_id ~= monsters.MONS_SLIME_CREATURE or
            blob_size < 2 or blob_size > 5) then
        error("invalid slime creature size " .. blob_size)
    end

    if not options.hp and not generated_lord and
        (hp < profile.minimum or hp > profile.maximum) then
        error("invalid " .. kind_id .. " HP " .. hp)
    end

    hp = hp * blob_size

    local loadout

    if not options.equipment then
        loadout = gear.loadout(ctx, kind_id, level_id)
    end
    local equipment = explicit_equipment(ctx, options)
    local monster = ctx:create()

    if options.mutant_beast then
        ctx:add(monster, component.MONSTER_MUTANT_BEAST, {
            tier = options.mutant_beast.tier,
            hit_dice = options.mutant_beast.hit_dice,
            facets = options.mutant_beast.facets,
        })
    end

    ctx:add(monster, "core.actor", {
        kind_id = kind_id,
        speed = generated_lord and generated_lord.speed or
            definition.speed or source.speed or 0,
    })
    ctx:add(monster, "core.monster_energy", { points = energy.initial })

    if generated_lord then
        -- The roller returns exactly the saved schema fields. Passing its
        -- record through avoids a second list of traits drifting out of sync.
        ctx:add(monster, component.PANDEMONIUM_LORD, generated_lord)
    end

    if generated_ugly then
        ctx:add(monster, component.UGLY_THING, generated_ugly)
    end
    ctx:add(monster, "core.health", {
        current = hp,
        max = hp,
    })
    ctx:add(monster, "core.combat", { shield_blocks = 0 })
    -- DES hostiles sleep unless their selected expression or map tag wakes
    -- them. Non-vault creation retains the source's awake mgen default.
    local sleep = options.origin and not options.generate_awake and
        not statues[kind_id] and
        (not options.attitude or options.attitude == attitudes.HOSTILE)

    ctx:add(monster, component.AI, {
        behavior = sleep and behaviors.SLEEP or behaviors.WANDER,
        target_x = 0,
        target_y = 0,
        memory_until_aut = 0,
        bat_retreat_actions = 0,
    })

    if options.patrolling then
        ctx:add(monster, component.MONSTER_PATROL, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    if blob_size > 1 then
        ctx:add(monster, component.SLIME_BLOB, { size = blob_size })
    end

    if options.hydra_heads and options.hydra_heads > 0 then
        ctx:add(monster, component.MONSTER_HYDRA_HEADS, {
            count = options.hydra_heads,
        })
    end
    create_loadout(ctx, monster, loadout, options.origin)
    give_explicit_equipment(ctx, monster, equipment, options.origin)

    if options.origin then
        ctx:add(monster, component.VAULT_ORIGIN,
            origin_component.for_entity(options.origin, kind_id))
    end

    if options.base_id or options.colour or options.attitude or
        options.god_id or options.spells or options.hp or options.hd or
        options.custom_name or options.name_adjective or
        options.name_species or options.database_name or options.tile then
        ctx:add(monster, component.VAULT_ACTOR_OVERRIDES, {
            base_id = options.base_id or "",
            variant = options.variant or "",
            colour = options.colour or "",
            attitude = options.attitude or "hostile",
            god_id = options.god_id or "",
            spells = options.spells or {},
            fixed_hp = options.hp or 0,
            -- Derived undead has no fixed HD in its generic catalog row.
            -- Its saved override must carry the selected corpse base's HD
            -- for later AI and spell decisions after the spawn call ends.
            hit_dice = options.hd or
                (not definition.hd and source.hd) or 0,
            custom_name = options.custom_name or "",
            name_adjective = options.name_adjective or false,
            name_species = options.name_species or false,
            database_name = options.database_name or "",
            tile = options.tile or "",
        })
    end

    if options.origin then
        prepare_habitat(ctx, source, level_id, x, y)
    end

    ctx:place_actor(monster, level_id, x, y)

    -- Species flags and generated lords install their source cloud ring at
    -- spawn, before the monster takes an ordinary action.
    cloud_ring.surround(ctx, monster)

    -- Shapeshifter's permanent enchantment picks its first body using the
    -- actual cell. Install all source statuses after placement so this
    -- shared policy can see the position and preserve a valid form lineage.
    vault_enchantments.install(ctx, monster,
        options.permanent_enchantments)

    if kind_id == monsters.MONS_SHAPESHIFTER or
        kind_id == monsters.MONS_GLOWING_SHAPESHIFTER then
        -- Source placement hides both base bodies behind an immediate form.
        shapeshifter.attach(ctx, monster, kind_id)
    end

    if not options.restore_identity then
        unique_history.mark(ctx, kind_id)
    end

    return monster
end

-- Summoned wrath monsters use the same saved weapon rolls as generated
-- population. This entry point equips an already placed actor without
-- creating a second monster or copying the loadout construction rules.
function factory.equip_generated(ctx, monster, kind_id, depth)
    create_loadout(ctx, monster,
        gear.loadout(ctx, kind_id, depth), nil)
end

return factory
