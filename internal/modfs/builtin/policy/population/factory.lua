-- Example: A monster assigned an incompatible habitat cell moves to a legal nearby cell.
local catalog = require("policy.catalog")
local items = require("policy.inventory.items")
local gear = require("policy.population.gear")
local hit_points = require("policy.population.hit_points")
local energy = require("policy.monster_energy")
local roster = require("policy.population.roster")
local component = require("constants.component")
local item_specs = require("policy.generation.vaults.specs.item")
local resolve = require("policy.generation.vaults.specs.resolve")
local origin_component = require("policy.population.origin")
local habitats = require("constants.monster_habitats")
local terrain = require("constants.terrain")
local monsters = require("ids.monsters")
local shapeshifter = require("policy.monsters.shapeshifter")

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

-- Authored vault equipment takes precedence over ordinary monster gear draws.
local function explicit_equipment(ctx, options)
    local selected = {}

    for _, slot in ipairs(options.equipment or {}) do
        local term = slot[ctx:random("vault_equipment", #slot) + 1]

        if term ~= "nothing" then
            local parsed = item_specs.parse(term, options.site)[1][1]
            local resolved = resolve.item(ctx, parsed, options.depth or 1, options.site)
            local definition = catalog.get("items", resolved.kind_id)
            local item = {
                kind_id = resolved.kind_id,
                quantity = resolved.quantity or 1,
                plus = 0,
                charges = 0,
                ego = "",
            }

            items.validate(item, definition)

            selected[#selected + 1] = {
                item = item,
                class = definition.class,
            }
        end
    end

    return selected
end

-- Create and equip each authored item while attaching the same vault origin as its monster.
local function give_explicit_equipment(ctx, monster, selected, origin)
    for index, entry in ipairs(selected) do
        local entity = ctx:create()
        local slot

        if entry.class == "OBJ_WEAPONS" then
            slot = "weapon"
        elseif entry.class == "OBJ_MISSILES" then
            slot = "missile"
        end

        ctx:add(entity, component.ITEM, entry.item)
        ctx:add(entity, component.CARRIED_BY, { holder = monster })

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
    local definition = catalog.get("monsters", kind_id)
    local source = definition

    if options.base_id then
        source = catalog.get("monsters", options.base_id)
    end

    if not source.average_hp_10x or source.average_hp_10x <= 0 then
        error("vault monster has no spawn profile " .. kind_id)
    end

    if not ctx:walkable(level_id, x, y) or ctx:actor_at(level_id, x, y) then
        error("cannot place monster " .. kind_id)
    end

    local profile = roster.profile(source.id)
    local hp = hit_points.roll(ctx, source.average_hp_10x)

    if hp < profile.minimum or hp > profile.maximum then
        error("invalid " .. kind_id .. " HP " .. hp)
    end

    local loadout

    if not options.equipment then
        loadout = gear.loadout(ctx, kind_id, level_id)
    end
    local equipment = explicit_equipment(ctx, options)
    local monster = ctx:create()
    ctx:add(monster, "core.actor", {
        kind_id = kind_id,
        speed = definition.speed or source.speed or 0,
    })
    ctx:add(monster, "core.monster_energy", { points = energy.initial })
    ctx:add(monster, "core.health", {
        current = hp,
        max = hp,
    })
    ctx:add(monster, "core.combat", { shield_blocks = 0 })
    ctx:add(monster, "core.ai", { behavior = "wander" })
    create_loadout(ctx, monster, loadout, options.origin)
    give_explicit_equipment(ctx, monster, equipment, options.origin)

    if options.origin then
        ctx:add(monster, component.VAULT_ORIGIN,
            origin_component.for_entity(options.origin, kind_id))
    end

    if options.base_id or options.colour or options.attitude or options.spells then
        ctx:add(monster, component.VAULT_ACTOR_OVERRIDES, {
            base_id = options.base_id or "",
            variant = options.variant or "",
            colour = options.colour or "",
            attitude = options.attitude or "hostile",
            spells = options.spells or {},
        })
    end

    if options.origin then
        prepare_habitat(ctx, source, level_id, x, y)
    end

    ctx:place_actor(monster, level_id, x, y)

    if kind_id == monsters.MONS_SHAPESHIFTER or
        kind_id == monsters.MONS_GLOWING_SHAPESHIFTER then
        -- Source placement hides both base bodies behind an immediate form.
        shapeshifter.attach(ctx, monster, kind_id)
    end

    return monster
end

return factory
