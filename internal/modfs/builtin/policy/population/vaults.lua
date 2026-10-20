-- Example: A keyed vault monster receives its source origin when instantiated.
local effects = require("constants.vault_effects")
local factory = require("policy.population.factory")
local item_specs = require("policy.generation.vaults.specs.item")
local monster_specs = require("policy.generation.vaults.specs.monster")
local vault_items = require("policy.population.vault_items")
local catalog = require("policy.catalog")
local component = require("constants.component")
local monster_flags = require("constants.monster_flags")
local origin_policy = require("policy.population.origin")
local trap_placement = require("policy.traps.placement")
local shop_spec = require("policy.generation.vaults.shop_spec")
local shop_generation = require("policy.shops.generation")
local streams = require("constants.rng_streams")
local bands = require("policy.population.bands")
local choice = require("policy.generation.vaults.specs.choice")
local resolve = require("policy.generation.vaults.specs.resolve")

local vaults = {}

-- Reserve every authored monster slot before any leader creates followers.
-- A band placed from an early record must not occupy a later vault glyph.
local function band_exclusions(level, excluded)
    local reserved = {}

    for key, value in pairs(excluded or {}) do
        reserved[key] = value
    end

    for _, record in ipairs(level.vault_records or {}) do
        if record.kind == effects.MONSTER then
            reserved[record.x .. ":" .. record.y] = true
        end
    end

    return reserved
end

-- Transfer source path, line, and vault ID to a resolver request.
local function source_site(record, arguments)
    return {
        path = arguments.path,
        vault_id = record.source_id,
        line = record.line,
        directive = record.directive,
        glyph = record.source,
    }
end

-- Identify the exact authored record and coordinate on each spawned entity.
local function origin(level, record)
    return {
        level_id = level.id,
        vault_id = record.source_id,
        record_index = record.index,
        occurrence = 1,
        spawn_x = record.x,
        spawn_y = record.y,
    }
end

-- Carry source site and depth into the monster resolver for an authored MONS record.
local function monster_options(record, level)
    local arguments = record.arguments
    local site = source_site(record, arguments)
    local selected = monster_specs.parse(arguments.selected_expression, site)[1][1]

    return {
        origin = origin(level, record),
        site = site,
        depth = level.id,
        base_id = arguments.base_id ~= "" and arguments.base_id or nil,
        blob_size = arguments.blob_size or 1,
        band = arguments.band or false,
        variant = arguments.variant,
        colour = arguments.colour ~= "" and arguments.colour or nil,
        attitude = arguments.attitude ~= "" and arguments.attitude or nil,
        spells = selected.spells,
        equipment = selected.equipment,
    }
end

-- Keep ITEM alternative choice separate from the later random-item roll.
local function item_selection(record)
    local arguments = record.arguments
    local site = source_site(record, arguments)
    local selected = item_specs.parse(arguments.selected_expression, site)[1][1]

    return {
        kind_id = arguments.kind_id,
        base_id = arguments.base_id ~= "" and arguments.base_id or nil,
        variant = arguments.variant,
        quantity = selected.quantity,
        quality = arguments.quality,
        request = arguments.request ~= "" and arguments.request or nil,
        generation_depth = arguments.generation_depth or 1,
        disc = arguments.disc ~= "" and arguments.disc or nil,
        numspells = arguments.numspells ~= 0 and arguments.numspells or nil,
        ident = arguments.ident ~= "" and arguments.ident or nil,
        tile = arguments.tile ~= "" and arguments.tile or nil,
        weapon_tile = arguments.weapon_tile ~= "" and
            arguments.weapon_tile or nil,
        item_name = arguments.item_name ~= "" and
            arguments.item_name or nil,
        site = site,
    }
end

-- Unique monsters already alive anywhere in the context cannot be spawned by another vault record.
local function duplicate_unique(ctx, kind_id)
    local definition = catalog.get("monsters", kind_id)
    local unique = false

    for _, flag in ipairs(definition.flags or {}) do
        unique = unique or flag == monster_flags.UNIQUE
    end

    if not unique then
        return false
    end

    for _, entity in ipairs(ctx:query({ component.ACTOR })) do
        local actor = ctx:get(entity, component.ACTOR)

        if actor.kind_id == kind_id then
            return true
        end
    end

    return false
end

-- A comma in MONS/KMONS supplies ordered fallbacks for the same cell. The
-- first choice was drawn during map placement; later choices only draw when
-- that choice cannot spawn, including when another vault placed its unique.
local function fallback_monster(ctx, level, record)
    local arguments = record.arguments
    local site = source_site(record, arguments)
    local slots = monster_specs.parse(arguments.expression, site)
    local random = {}

    -- Keep each alternative draw on the established vault placement stream.
    function random:roll(bound)
        return ctx:random(streams.PLACEMENT, bound)
    end

    for index = 2, #slots do
        local selected = choice.pick(random, slots[index])
        local resolved = resolve.monster(ctx, selected, level.id, site)

        if not resolved.no_spawn then
            arguments.selected_expression = selected.source
            arguments.kind_id = resolved.kind_id
            arguments.base_id = resolved.base_id or ""
            arguments.blob_size = resolved.blob_size or 1
            arguments.band = resolved.band or false
            arguments.variant = resolved.variant or ""
            arguments.colour = resolved.colour or ""
            arguments.attitude = resolved.attitude or ""
            arguments.spells = resolved.spells and
                table.concat(resolved.spells, "|") or ""
            arguments.generate_awake = resolved.generate_awake or false
            arguments.no_spawn = false
            record.identity = selected.name
            record.pending = true

            return true
        end
    end

    return false
end

-- Find previously created equipment by record origin when a shop needs its stock.
local function generated_gear(ctx, level, record)
    local gear = {}

    for _, entity in ipairs(ctx:query({ component.VAULT_ORIGIN, component.ITEM })) do
        local source = ctx:get(entity, component.VAULT_ORIGIN)

        if source.level_id == level.id and source.record_index == record.index and
            source.vault_id == record.source_id and source.occurrence > 1 and
            source.occurrence < origin_policy.CORPSE_OCCURRENCE then
            gear[#gear + 1] = {
                occurrence = source.occurrence,
                kind_id = ctx:get(entity, component.ITEM).kind_id,
            }
        end
    end

    if #gear > 0 then
        return gear
    end

    return nil
end

-- Shop inventory uses its own RNG stream and can refer to gear generated by earlier records.
local function materialize_shop(ctx, level, record)
    local site = {
        path = record.arguments and record.arguments.path or
            "vaults/shop/" .. record.source_id .. ".des",
        vault_id = record.source_id,
        line = record.line,
        directive = record.directive,
        glyph = record.source,
    }
    local alternatives = shop_spec.parse(record.identity, site)
    local random = {}

    -- Shop stock draws from the shop stream rather than the map layout stream.
    function random:roll(bound)
        return ctx:random(streams.SHOP, bound)
    end

    local selected = shop_spec.choose(random, alternatives)

    selected.level_id = level.id
    selected.x = record.x
    selected.y = record.y
    selected.depth = level.id

    shop_generation.place(ctx, selected)

    return {
        level_id = level.id,
        index = record.index,
    }
end

-- Process typed vault records in source order so terrain, actors, items, and shops see prior effects.
function vaults.materialize(ctx, level, excluded)
    local actors = 0
    local followers = 0
    local materialized = {}
    local reserved = band_exclusions(level, excluded)

    for _, record in ipairs(level.vault_records or {}) do
        local arguments = record.arguments or {}

        if record.kind == effects.FEATURE and
            shop_spec.is_shop(record.identity) then
            materialized[#materialized + 1] =
                materialize_shop(ctx, level, record)
        elseif (record.kind == effects.FEATURE or
            record.kind == effects.SOURCE_FEATURE) and
            trap_placement.is_trap(record) then
            local kind_id = trap_placement.materialize(ctx, level, record)

            if kind_id then
                materialized[#materialized + 1] = {
                    level_id = level.id,
                    index = record.index,
                    kind_id = kind_id,
                }
            end
        elseif (arguments.kind_id and arguments.kind_id ~= "") or
            (record.kind == effects.MONSTER and
                (arguments.monster_slots or 0) > 1) then
            local no_spawn = false
            local gear

            if not ctx:walkable(level.id, record.x, record.y) then
                error(string.format("%s:%d: vault %s: blocked authored %s cell",
                    arguments.path, record.line, record.source_id, record.kind))
            end

            -- Skip an occupied cell or duplicate unique before spawning the requested vault actor.
            if record.kind == effects.MONSTER then
                if ctx:actor_at(level.id, record.x, record.y) then
                    error(string.format("%s:%d: vault %s: two actors at glyph %s",
                        arguments.path, record.line, record.source_id, record.source))
                end

                if arguments.no_spawn or arguments.kind_id == "" or
                    duplicate_unique(ctx, arguments.kind_id) then
                    no_spawn = not fallback_monster(ctx, level, record)
                end

                if not no_spawn then
                    local spawned = factory.spawn(ctx, arguments.kind_id, level.id,
                        record.x, record.y, monster_options(record, level))
                    if arguments.band then
                        local placed = bands.spawn(ctx, spawned, level, reserved)

                        actors = actors + placed
                        followers = followers + placed
                    end
                    gear = generated_gear(ctx, level, record)
                    actors = actors + 1
                end
            -- Materialize item records after terrain and monster records have been interpreted in source order.
            elseif record.kind == effects.ITEM then
                local _, actual_kind = vault_items.create(ctx,
                    item_selection(record), level.id,
                    record.x, record.y, origin(level, record))
                arguments.kind_id = actual_kind
            end

            materialized[#materialized + 1] = {
                level_id = level.id,
                index = record.index,
                no_spawn = no_spawn,
                gear = gear,
                kind_id = record.kind == effects.ITEM and
                    arguments.kind_id or nil,
            }
        end
    end

    -- A band follower has no authored vault record of its own. The
    -- population budget must still include it for save and XP accounting.
    return actors, materialized, followers
end

return vaults
