local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local component = require("constants.component")
local kinds = require("constants.artefact_kinds")
local properties = require("ids.artefact_properties")
local sentinels = require("constants.artefact_base_sentinels")
local status = require("constants.unique_item_status")
local property_rules = require(
    "policy.item_generation.artefacts.property_rules")

local artefacts = {}
local random_property = {}

for _, id in pairs(properties) do
    random_property[id] = true
end

local function fail(ctx, entity, detail)
    error("artefact item " .. ctx:id(entity) .. " " .. detail)
end

local function validate_unique(ctx, entity, item, artefact, seen)
    local okay, definition = pcall(catalog.get, "artefacts",
        artefact.unique_id)

    if not okay then
        fail(ctx, entity, "has unknown unique " .. artefact.unique_id)
    end

    if seen[artefact.unique_id] then
        fail(ctx, entity, "duplicates unique " .. artefact.unique_id)
    end

    seen[artefact.unique_id] = true

    if definition.kind_id ~= item.kind_id and
        not (definition.kind_id == sentinels.RANDOM_RING and
            catalog.get("items", item.kind_id).class ==
                classes.OBJ_JEWELLERY) then
        fail(ctx, entity, "has wrong base kind for " .. artefact.unique_id)
    end

    for name, value in pairs(definition.properties) do
        if artefact.properties[name] ~= value then
            fail(ctx, entity, "changed source property " .. name)
        end
    end

    for name in pairs(artefact.properties) do
        if definition.properties[name] == nil then
            fail(ctx, entity, "has extra unique property " .. name)
        end
    end

    local player = ctx:player()
    local history = ctx:get(player, component.PLAYER_UNIQUE_HISTORY)

    if not history or
        (history.status[artefact.unique_id] ~= status.ORDINARY and
            history.status[artefact.unique_id] ~= status.NONLEVEL) then
        fail(ctx, entity, "has no matching unique history")
    end
end

local function validate_random(ctx, entity, item, artefact)
    local definition = catalog.get("items", item.kind_id)

    if definition.class ~= classes.OBJ_WEAPONS and
        definition.class ~= classes.OBJ_ARMOUR and
        definition.class ~= classes.OBJ_JEWELLERY and
        definition.class ~= classes.OBJ_BOOKS then
        fail(ctx, entity, "has invalid random artefact base")
    end

    if artefact.unique_id ~= "" then
        fail(ctx, entity, "has invalid random artefact identity")
    end

    for id in pairs(artefact.properties) do
        if not random_property[id] then
            fail(ctx, entity, "has unknown random property " .. id)
        end

        if definition.class ~= classes.OBJ_BOOKS and
            not property_rules.compatible(id, definition,
                artefact.properties, artefact.brand) then
            fail(ctx, entity, "has incompatible random property " .. id)
        end
    end

    if definition.class ~= classes.OBJ_BOOKS and
        property_rules.bad(definition, artefact.properties,
            artefact.brand) then
        fail(ctx, entity, "has invalid random property combination")
    end
end

function artefacts.validate(ctx)
    local seen = {}

    for _, entity in ipairs(ctx:query({ component.ITEM_ARTEFACT })) do
        local item = ctx:get(entity, component.ITEM)
        local artefact = ctx:get(entity, component.ITEM_ARTEFACT)

        if not item or artefact.name == "" or
            artefact.appearance == "" then
            fail(ctx, entity, "has incomplete identity")
        end

        if artefact.kind == kinds.UNIQUE then
            validate_unique(ctx, entity, item, artefact, seen)
        elseif artefact.kind == kinds.RANDOM then
            validate_random(ctx, entity, item, artefact)
        else
            fail(ctx, entity, "has unknown kind " .. artefact.kind)
        end

        for id in pairs(artefact.known) do
            if artefact.properties[id] == nil then
                fail(ctx, entity, "knows missing property " .. id)
            end
        end
    end

    return {}
end

register.policy({
    id = "save.validate_artefacts",
    run = artefacts.validate,
})

return artefacts
