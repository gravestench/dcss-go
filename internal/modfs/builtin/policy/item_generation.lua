local catalog = require("policy.catalog")
local choice = require("policy.item_generation.class_choice")
local class_policies = require("policy.item_generation.catalog")
local pool = require("policy.item_generation.pool")
local materialize = require("policy.item_generation.materialize")
local quality = require("constants.vault_item_quality")
local artefacts = require("policy.item_generation.artefacts")
local source_level = require("policy.item_generation.source_level")
local unique_artefacts =
    require("policy.item_generation.artefacts.unique")
local component = require("constants.component")
local purpose = require("constants.item_generation_purpose")

local generation = {}

local valid_quality = {
    [quality.ORDINARY] = true,
    [quality.STAR] = true,
    [quality.GIFT] = true,
    [quality.GOOD] = true,
    [quality.SUPERB] = true,
    [quality.RANDART] = true,
}

-- Include the caller site in generation errors so a bad vault item can be located.
local function fail(request, detail)
    error(tostring(request.site) .. ": item generation " .. detail)
end

-- Reject invalid depth, quality, and site before any item-generation draw.
local function validate_request(request)
    if type(request) ~= "table" or
        type(request.depth) ~= "number" or
        request.depth < 1 or
        request.depth % 1 ~= 0 then
        error("item generation requires a positive integer depth at " ..
            tostring(request and request.site) .. ": " ..
            tostring(request and request.depth))
    end

    if not valid_quality[request.quality] then
        fail(request, "has invalid quality " .. tostring(request.quality))
    end

    if type(request.site) ~= "string" or request.site == "" then
        error("item generation requires caller site")
    end

    if request.purpose == purpose.GOD_GIFT and
        (type(request.god_id) ~= "string" or
            request.god_id == "") then
        fail(request, "requires a gift god ID")
    end
end

-- A vault's fixed kind still passes class and generation checks before any RNG draw.
local function fixed_definition(request)
    local okay, definition = pcall(catalog.get, "items", request.kind_id)

    if not okay then
        fail(request, "unknown fixed kind " .. tostring(request.kind_id))
    end

    if request.class_id and request.class_id ~= definition.class then
        fail(request, "fixed kind " .. definition.id ..
            " is outside class " .. request.class_id)
    end

    if not definition.generation or definition.generation.mode == "none" then
        fail(request, "fixed kind " .. definition.id .. " is not generated")
    end

    return definition
end

-- Fixed kinds take the direct path; random requests use the class policy's picker or pool.
local function selected_definition(ctx, class_id, request, policy)
    if request.kind_id then
        local definition = fixed_definition(request)

        if not policy.eligible(ctx, definition, request) then
            fail(request, "fixed kind " .. definition.id .. " is ineligible")
        end

        return definition
    end

    if policy.pick then
        return policy.pick(ctx, request)
    end

    return pool.select(ctx, class_id, request, policy)
end

-- Example: a randart request rolls a class and subtype, then requires the artefact path to succeed.
-- Resolve the request once through class choice, subtype, and artefact policy;
-- the returned roll stays data-only until materialization creates its entity.
function generation.roll(ctx, request)
    validate_request(request)

    local effective = source_level.request(request)
    local fixed = effective.kind_id and fixed_definition(effective)
    local class_id = fixed and fixed.class or choice.pick(ctx, effective)
    local policy = class_policies.policy(class_id)
    local definition = selected_definition(ctx, class_id, effective, policy)
    local result = {
        kind_id = definition.id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = request.ego or "",
        components = {},
        source = request,
    }

    local explicit_unique = request.unique_id and
        catalog.get("artefacts", request.unique_id)
    local artefact_applied

    if explicit_unique then
        artefact_applied =
            unique_artefacts.apply(ctx, explicit_unique, request, result)

        if not artefact_applied then
            artefact_applied = artefacts.explicit_duplicate(ctx,
                explicit_unique, request, result)

            if not artefact_applied then
                fail(request, "unique artefact " .. request.unique_id ..
                    " has no usable fallback")
            end
        end
    else
        artefact_applied = artefacts.roll(ctx, definition, effective, result)
    end

    if not artefact_applied then
        if request.quality == quality.RANDART then
            fail(request, "cannot make random artefact from " ..
                definition.id)
        end

        policy.roll(ctx, definition, effective, result)
    end

    if request.quantity then
        result.quantity = request.quantity
    end

    -- Authored item modifiers take precedence over the base generator's
    -- random enchantment, charge, and brand rolls.
    if request.plus then
        result.plus = request.plus
    end

    if request.charges then
        result.charges = request.charges
    end

    if request.ego then
        result.ego = request.ego
    end

    if request.purpose == purpose.GOD_GIFT then
        result.components[component.ITEM_PROVENANCE] = {
            purpose = purpose.GOD_GIFT,
            god_id = request.god_id,
        }
    end

    if request.mundane then
        result.plus = 0
        result.ego = ""
    elseif request.damaged then
        result.plus = -1
    end

    return result
end

-- Materialize a rolled result only after all generation decisions are complete.
function generation.create(ctx, result, location)
    return materialize.create(ctx, result, location)
end

return generation
