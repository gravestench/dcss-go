local definitions = require("policy.catalog")
local policies = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")
local sentinels = require("constants.artefact_base_sentinels")
local brands = require("constants.weapon_brands")
local armour_egos = require("constants.armour_egos")

local validation = {}

local modes = {
    random = true,
    forced = true,
    none = true,
}

local rarity_ids = {
    RARITY_VERY_COMMON = true,
    RARITY_COMMON = true,
    RARITY_UNCOMMON = true,
    RARITY_RARE = true,
    RARITY_VERY_RARE = true,
    RARITY_NONE = true,
}

local metadata_fields = {
    mode = true,
    rarity = true,
    weight = true,
    commonness = true,
    min_depth = true,
    spells = true,
}

-- Source: crawl-ref/source/art-data.txt field declarations. These are
-- source art properties, not arbitrary Lua fields on an artefact record.
local artefact_properties = {
    plus = true,
    value = true,
    ac = true,
    ev = true,
    str = true,
    int = true,
    dex = true,
    fire = true,
    cold = true,
    life = true,
    will = true,
    hp = true,
    mp = true,
    regen = true,
    slay = true,
    stealth = true,
    angry = true,
    base_acc = true,
    base_dam = true,
    base_delay = true,
    sh = true,
}

local function fail(definition, detail)
    local origin = register.origin("items", definition.id)

    error(origin .. ": item " .. definition.id .. " " .. detail)
end

local function nonnegative(definition, field)
    local value = definition.generation[field]

    if value == nil then
        return
    end

    if type(value) ~= "number" or value < 0 or value % 1 ~= 0 then
        fail(definition, field .. " must be a nonnegative integer")
    end
end

function validation.definition(definition)
    if type(definition.generation) ~= "table" then
        fail(definition, "has no generation metadata")
    end

    local generation = definition.generation

    if not modes[generation.mode] then
        fail(definition, "has invalid generation mode " ..
            tostring(generation.mode))
    end

    for field, value in pairs(generation) do
        if not metadata_fields[field] then
            fail(definition, "has unknown generation " .. field ..
                " " .. tostring(value))
        end
    end

    if generation.rarity and not rarity_ids[generation.rarity] then
        fail(definition, "has unknown rarity " .. generation.rarity)
    end

    nonnegative(definition, "weight")
    nonnegative(definition, "commonness")
    nonnegative(definition, "min_depth")

    if generation.mode == "random" and generation.weight == 0 then
        fail(definition, "has zero random weight")
    end
end

local function validate_policy_weight(definition, policy)
    local okay, weight = pcall(policy.weight, nil, definition, {
        depth = 1,
    })

    if not okay then
        error(policies.path(definition.class) .. " weight for " ..
            definition.id .. " failed: " .. tostring(weight))
    end

    if type(weight) ~= "number" or weight < 0 or weight % 1 ~= 0 then
        error(policies.path(definition.class) .. " weight for " ..
            definition.id .. " must be a nonnegative integer")
    end

    return weight
end

local function validate_artefact(artefact)
    local origin = register.origin("artefacts", artefact.id)
    local base

    if not modes[artefact.generation and artefact.generation.mode] then
        error(origin .. ": artefact " .. artefact.id ..
            " has invalid generation mode")
    end

    if artefact.kind_id == sentinels.RANDOM_RING then
        if artefact.class ~= classes.OBJ_JEWELLERY then
            error(origin .. ": artefact " .. artefact.id ..
                " uses random-ring selector outside jewellery")
        end
    elseif artefact.class ~= classes.OBJ_UNASSIGNED then
        local okay, found = pcall(definitions.get, "items", artefact.kind_id)

        if not okay or found.class ~= artefact.class then
            error(origin .. ": artefact " .. artefact.id ..
                " has incompatible base kind " .. tostring(artefact.kind_id))
        end

        base = found
    end

    if artefact.fallback ~= "" and artefact.fallback ~= nil then
        local fallback = artefact.fallback

        if type(fallback) ~= "table" or
            type(fallback.class) ~= "string" or
            type(fallback.kind_id) ~= "string" then
            error(origin .. ": artefact " .. artefact.id ..
                " has malformed fallback")
        end

        if fallback.kind_id ~= sentinels.RANDOM_KIND and
            fallback.kind_id ~= sentinels.DUMMY_UNASSIGNED then
            local okay, base = pcall(definitions.get, "items",
                fallback.kind_id)

            if not okay or base.class ~= fallback.class then
                error(origin .. ": artefact " .. artefact.id ..
                    " has incompatible fallback kind " ..
                    fallback.kind_id)
            end
        end
    end

    for name, value in pairs(artefact.properties or {}) do
        if not artefact_properties[name] then
            error(origin .. ": artefact " .. artefact.id ..
                " has unknown property " .. tostring(name))
        end

        if type(value) ~= "number" or value % 1 ~= 0 then
            error(origin .. ": artefact " .. artefact.id ..
                " property " .. name .. " must be an integer")
        end
    end

    if base then
        local values = artefact.properties or {}

        if values.plus ~= nil and base.class == classes.OBJ_JEWELLERY and
            (not base.jewellery or not base.jewellery.pluses) then
            error(origin .. ": artefact " .. artefact.id ..
                " has a plus on non-plus jewellery")
        end

        if (values.base_acc ~= nil or values.base_dam ~= nil or
            values.base_delay ~= nil) and
            base.class ~= classes.OBJ_WEAPONS then
            error(origin .. ": artefact " .. artefact.id ..
                " has weapon base properties on a non-weapon")
        end

        if artefact.brand ~= "" then
            local allowed = base.class == classes.OBJ_WEAPONS and brands or
                base.class == classes.OBJ_ARMOUR and armour_egos or {}
            local found = false

            for _, id in pairs(allowed) do
                if id == artefact.brand then
                    found = true
                    break
                end
            end

            if not found then
                error(origin .. ": artefact " .. artefact.id ..
                    " has an incompatible brand")
            end
        end
    end
end

validation.artefact = validate_artefact

function validation.check()
    local generated_classes = {}
    local positive_pools = {}

    for _, definition in ipairs(definitions.all("items")) do
        validation.definition(definition)

        if definition.generation.mode ~= "none" then
            local policy = policies.policy(definition.class)
            local weight = validate_policy_weight(definition, policy)

            if definition.generation.mode == "random" and weight > 0 then
                positive_pools[definition.class] = true
            end

            generated_classes[definition.class] = true
        end
    end

    for _, class_id in ipairs(policies.classes()) do
        if not generated_classes[class_id] then
            error(policies.path(class_id) .. " has no generated items")
        end

        local policy = policies.policy(class_id)

        if not policy.pick and not positive_pools[class_id] and
            class_id ~= classes.OBJ_CORPSES and
            class_id ~= classes.OBJ_RUNES and
            class_id ~= classes.OBJ_ORBS then
            error(policies.path(class_id) .. " has no positive random pool")
        end
    end

    for _, artefact in ipairs(definitions.all("artefacts")) do
        validate_artefact(artefact)
    end
end

return validation
