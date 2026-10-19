local streams = require("constants.rng_streams")
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local component = require("constants.component")
local history = require("policy.item_generation.artefacts.history")
local status = require("constants.unique_item_status")
local sentinels = require("constants.artefact_base_sentinels")
local jewellery = require("constants.jewellery_kind")
local kinds = require("constants.artefact_kinds")
local item_ids = require("ids.items")
local policies = require("policy.item_generation.catalog")
local pool = require("policy.item_generation.pool")

local unique = {}

-- Example: unique.eligible(artefact) excludes sentinel records without a random-generation mode.
-- Only assigned random-mode artefacts enter the ordinary unique candidate pool.
function unique.eligible(definition)
    return definition.generation and
        definition.generation.mode == "random" and
        definition.class ~= classes.OBJ_UNASSIGNED
end

-- Random-ring sentinels match ring bases; other uniques need a compatible item kind.
local function matches_kind(artefact, base, request)
    if artefact.class ~= base.class then
        return false
    end

    if artefact.kind_id == sentinels.RANDOM_RING then
        return base.jewellery and
            base.jewellery.kind == jewellery.RING
    end

    return request.allow_class or artefact.kind_id == base.id
end

-- Preferred depth multiplies a unique's selection weight without making deeper finds impossible.
local function source_weight(artefact, depth)
    local preferred = artefact.generation.preferred_max_depth

    if not preferred then
        return 10
    end

    return depth <= preferred and 100 or 1
end

-- Reservoir weighting spans eligible IDs in stable catalog order on one RNG stream.
function unique.choose(ctx, base, request)
    local player = ctx:player()
    local selected
    local seen_weight = 0

    -- Source: crawl-ref/source/artefact.cc. Reservoir selection
    -- traverses stable catalog ID order and allows nonlevel duplicates as fallback choices.
    for _, candidate in ipairs(catalog.all("artefacts")) do
        local previous = history.status(ctx, player, candidate.id)

        if unique.eligible(candidate) and
            matches_kind(candidate, base, request) and
            (previous == nil or previous == status.NONLEVEL) then
            local weight = source_weight(candidate, request.depth)

            seen_weight = seen_weight + weight

            if ctx:random(streams.ITEM_GENERATION, seen_weight) < weight then
                selected = candidate
            end
        end
    end

    return selected
end

-- Claim the unique only after copying its properties into the result component.
function unique.apply(ctx, chosen, request, result)
    if not unique.eligible(chosen) then
        error("ineligible unique artefact " .. tostring(chosen.id))
    end

    local player = ctx:player()
    local previous = history.status(ctx, player, chosen.id)

    if previous == status.ORDINARY then
        error("duplicate unique artefact " .. chosen.id)
    end

    if previous == status.NONLEVEL then
        return false
    end

    local properties = {}
    local known = {}
    local flags = {}

    for name, value in pairs(chosen.properties or {}) do
        properties[name] = value
        known[name] = false
    end

    for index, flag in ipairs(chosen.flags or {}) do
        flags[index] = flag
    end

    if chosen.kind_id ~= sentinels.RANDOM_RING then
        result.kind_id = chosen.kind_id
    end
    result.plus = properties.plus or 0
    result.ego = ""
    result.components[component.ITEM_ARTEFACT] = {
        kind = kinds.UNIQUE,
        unique_id = chosen.id,
        seed = 0,
        name = chosen.name,
        appearance = chosen.appearance ~= "" and
            chosen.appearance or chosen.name,
        brand = chosen.brand,
        properties = properties,
        known = known,
        flags = flags,
    }

    history.mark(ctx, player, chosen.id, request.purpose)

    return true
end

-- Fallback uses the class generator when a selected unique cannot be placed.
local function random_kind(ctx, class_id, request)
    local policy = policies.policy(class_id)
    local selection = {
        depth = request.depth,
        site = request.site,
    }

    if policy.pick then
        return policy.pick(ctx, selection)
    end

    return pool.select(ctx, class_id, selection, policy)
end

-- Convert a nonlevel duplicate into a compatible random artefact base.
function unique.fallback(ctx, chosen, request, result)
    -- Source: crawl-ref/source/makeitem.cc:_setup_fallback_randart.
    -- A nonlevel unique retains its source fallback subtype, then becomes a
    -- random artefact. The unique remains recorded in player history.
    local fallback = type(chosen.fallback) == "table" and
        chosen.fallback or nil
    local class_id = fallback and fallback.class or chosen.class
    local kind_id = fallback and fallback.kind_id or chosen.kind_id
    local definition

    if kind_id == sentinels.RANDOM_KIND or
        kind_id == item_ids.AMU_NOTHING then
        definition = random_kind(ctx, class_id, request)
    elseif kind_id == sentinels.RANDOM_RING then
        definition = catalog.get("items", result.kind_id)
    else
        definition = catalog.get("items", kind_id)
    end

    if class_id == classes.OBJ_STAVES or
        kind_id == item_ids.WPN_STAFF then
        -- The source turns an enhancer-staff fallback into a quarterstaff
        -- before calling the weapon randart generator.
        definition = catalog.get("items", item_ids.WPN_QUARTERSTAFF)
    end

    result.kind_id = definition.id

    local brand = chosen.fallback_brand

    if not brand or brand == "" then
        if class_id == chosen.class then
            brand = chosen.brand
        end
    end

    return definition, brand
end

return unique
