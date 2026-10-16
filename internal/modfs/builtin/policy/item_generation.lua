local catalog = require("policy.catalog")
local choice = require("policy.item_generation.class_choice")
local class_policies = require("policy.item_generation.catalog")
local pool = require("policy.item_generation.pool")
local materialize = require("policy.item_generation.materialize")
local quality = require("constants.vault_item_quality")
local artefacts = require("policy.item_generation.artefacts")
local source_level = require("policy.item_generation.source_level")

local generation = {}

local valid_quality = {
    [quality.ORDINARY] = true,
    [quality.STAR] = true,
    [quality.GOOD] = true,
    [quality.SUPERB] = true,
    [quality.RANDART] = true,
}

local function fail(request, detail)
    error(tostring(request.site) .. ": item generation " .. detail)
end

local function validate_request(request)
    if type(request) ~= "table" or
        type(request.depth) ~= "number" or
        request.depth < 1 or
        request.depth % 1 ~= 0 then
        error("item generation requires a positive integer depth")
    end

    if not valid_quality[request.quality] then
        fail(request, "has invalid quality " .. tostring(request.quality))
    end

    if type(request.site) ~= "string" or request.site == "" then
        error("item generation requires caller site")
    end
end

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

    if not artefacts.roll(ctx, definition, effective, result) then
        if request.quality == quality.RANDART then
            fail(request, "cannot make random artefact from " ..
                definition.id)
        end

        policy.roll(ctx, definition, effective, result)
    end

    if request.quantity then
        result.quantity = request.quantity
    end

    return result
end

function generation.create(ctx, result, location)
    return materialize.create(ctx, result, location)
end

return generation
