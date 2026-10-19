local classes = require("ids.object_classes")
local catalog = require("policy.catalog")
local artefact_ids = require("ids.artefacts")
local item_ids = require("ids.items")
local purpose = require("constants.item_generation_purpose")
local quality = require("constants.vault_item_quality")
local random = require("policy.item_generation.artefacts.random")
local source = require("policy.item_generation.source_roll")
local unique = require("policy.item_generation.artefacts.unique")

local artefacts = {}

-- Try an eligible unique before randart fallback and retain the selected ID for duplicate handling.
local function unique_request(ctx, definition, request, result)
    local selection = {
        depth = request.depth,
        purpose = request.purpose,
        allow_class = request.kind_id == nil,
    }
    local chosen = unique.choose(ctx, definition, selection)

    if not chosen then
        return false, nil
    end

    return unique.apply(ctx, chosen, request, result), chosen
end

-- A nonlevel duplicate becomes a randart while preserving its compatible brand.
local function fallback(ctx, chosen, request, result)
    local definition, brand = unique.fallback(ctx, chosen, request, result)

    return random.apply(ctx, definition, result, brand)
end

-- Forced randarts skip the ordinary rarity gate; uniques are tried before the random-artefact fallback.
local function weapon_or_armour(ctx, definition, request, result)
    local forced = request.quality == quality.RANDART

    if not forced and
        not source.chance(ctx, 101 + request.depth * 3, 4000) then
        return false
    end

    if not forced and
        source.chance(ctx, 1, request.quality == quality.GOOD and 7 or 20) then
        local applied, selected = unique_request(ctx, definition, request,
            result)

        if applied then
            return true
        end

        if selected then
            return fallback(ctx, selected, request, result)
        end
    end

    return random.apply(ctx, definition, result)
end

-- Jewellery uses separate unique and randart gates from weapon and armour generation.
local function jewellery(ctx, definition, request, result)
    if request.quality ~= quality.RANDART and
        source.chance(ctx, 1, 20) and
        source.chance(ctx, 101 + request.depth * 3, 2000) then
        local applied, selected = unique_request(ctx, definition, request,
            result)

        if applied then
            return true
        end

        if selected then
            return fallback(ctx, selected, request, result)
        end
    end

    if request.quality ~= quality.RANDART and
        not source.chance(ctx, 101 + request.depth * 3, 4000) then
        return false
    end

    return random.apply(ctx, definition, result)
end

-- Enhancer staff uniques are permitted only for gift or acquirement requests.
local function staff(ctx, request, result)
    if not request.allow_uniques or
        (request.purpose ~= purpose.ACQUIREMENT and
            request.purpose ~= purpose.GOD_GIFT) or
        not source.chance(ctx, 1,
            request.quality == quality.GOOD and 27 or 100) then
        return false
    end

    -- Source: crawl-ref/source/makeitem.cc:_generate_staff_item.
    -- Enhancer uniques are declared as weapons with WPN_STAFF as base.
    local base = catalog.get("items", item_ids.WPN_STAFF)
    local applied, chosen = unique_request(ctx, base, {
        depth = request.depth,
        purpose = request.purpose,
        site = request.site,
        kind_id = base.id,
    }, result)

    if applied then
        return true
    end

    if chosen and chosen.id == artefact_ids.UNRAND_OLGREB then
        result.kind_id = item_ids.STAFF_POISON
    end

    return false
end

-- Example: acquirement can route a staff through enhancer-unique selection, unlike ordinary staff generation.
-- Gate uniqueness once, then dispatch class-specific odds and fallback handling.
function artefacts.roll(ctx, definition, request, result)
    if not request.allow_uniques and request.quality ~= quality.RANDART then
        return false
    end

    if definition.class == classes.OBJ_WEAPONS or
        definition.class == classes.OBJ_ARMOUR then
        return weapon_or_armour(ctx, definition, request, result)
    elseif definition.class == classes.OBJ_JEWELLERY then
        return jewellery(ctx, definition, request, result)
    elseif definition.class == classes.OBJ_STAVES then
        return staff(ctx, request, result)
    end

    return false
end

return artefacts
