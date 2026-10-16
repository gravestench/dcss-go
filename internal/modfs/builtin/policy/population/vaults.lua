local effects = require("constants.vault_effects")
local factory = require("policy.population.factory")
local item_specs = require("policy.generation.vaults.specs.item")
local monster_specs = require("policy.generation.vaults.specs.monster")
local vault_items = require("policy.population.vault_items")
local catalog = require("policy.catalog")
local component = require("constants.component")
local monster_flags = require("constants.monster_flags")
local origin_policy = require("policy.population.origin")

local vaults = {}

local function source_site(record, arguments)
    return {
        path = arguments.path,
        vault_id = record.source_id,
        line = record.line,
        directive = record.directive,
        glyph = record.source,
    }
end

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

local function monster_options(record, level)
    local arguments = record.arguments
    local site = source_site(record, arguments)
    local selected = monster_specs.parse(arguments.selected_expression, site)[1][1]

    return {
        origin = origin(level, record),
        site = site,
        depth = level.id,
        base_id = arguments.base_id ~= "" and arguments.base_id or nil,
        variant = arguments.variant,
        colour = arguments.colour ~= "" and arguments.colour or nil,
        attitude = arguments.attitude ~= "" and arguments.attitude or nil,
        spells = selected.spells,
        equipment = selected.equipment,
    }
end

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
    }
end

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

function vaults.materialize(ctx, level)
    local actors = 0
    local materialized = {}

    for _, record in ipairs(level.vault_records or {}) do
        local arguments = record.arguments or {}

        if arguments.kind_id and arguments.kind_id ~= "" then
            local no_spawn = false
            local gear

            if not ctx:walkable(level.id, record.x, record.y) then
                error(string.format("%s:%d: vault %s: blocked authored %s cell",
                    arguments.path, record.line, record.source_id, record.kind))
            end

            if record.kind == effects.MONSTER then
                if ctx:actor_at(level.id, record.x, record.y) then
                    error(string.format("%s:%d: vault %s: two actors at glyph %s",
                        arguments.path, record.line, record.source_id, record.source))
                end

                if duplicate_unique(ctx, arguments.kind_id) then
                    no_spawn = true
                else
                    factory.spawn(ctx, arguments.kind_id, level.id,
                        record.x, record.y, monster_options(record, level))
                    gear = generated_gear(ctx, level, record)
                    actors = actors + 1
                end
            elseif record.kind == effects.ITEM then
                vault_items.create(ctx, item_selection(record), level.id,
                    record.x, record.y, origin(level, record))
            end

            materialized[#materialized + 1] = {
                level_id = level.id,
                index = record.index,
                no_spawn = no_spawn,
                gear = gear,
            }
        end
    end

    return actors, materialized
end

return vaults
