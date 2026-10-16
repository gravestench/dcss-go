-- Source: acquire.cc:shuffled_acquirement_classes and acquirement_menu.
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local component = require("constants.component")
local equipment = require("policy.inventory.equipment")
local enchantable = require("policy.scrolls.enchantable")
local item_ids = require("ids.items")
local items = require("policy.inventory.items")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")

local offers = {}

local class_choices = {
    classes.OBJ_ARMOUR,
    classes.OBJ_WEAPONS,
    classes.OBJ_STAVES,
    classes.OBJ_JEWELLERY,
    classes.OBJ_BOOKS,
}

local function classes_for(ctx, player)
    local choices = {}
    local no_armour = mutation_levels.effective(ctx, player,
        mutations.MUT_NO_ARMOUR) > 0
    local no_grasping = mutation_levels.effective(ctx, player,
        mutations.MUT_NO_GRASPING) > 0

    for _, class_id in ipairs(class_choices) do
        if (class_id ~= classes.OBJ_ARMOUR or not no_armour) and
            ((class_id ~= classes.OBJ_WEAPONS and
                class_id ~= classes.OBJ_STAVES) or not no_grasping) then
            choices[#choices + 1] = class_id
        end
    end

    for index = #choices, 2, -1 do
        local other = 1 + ctx:random("acquirement", index)

        choices[index], choices[other] = choices[other], choices[index]
    end

    return choices
end

local function eligible(ctx, player, species, kind, class_id)
    if kind.class ~= class_id or kind.explicitly_removed or
        kind.status == "removed" or kind.status == "enum_only" then
        return false
    end

    if class_id == classes.OBJ_ARMOUR then
        return equipment.can_wear(ctx, player, species, kind)
    end

    if class_id == classes.OBJ_WEAPONS then
        return kind.weapon and
            equipment.weapon_supported(kind.weapon.skill_id)
    end

    return true
end

local function pick_kind(ctx, player, class_id)
    local choice = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", choice.species_id)
    local candidates = {}

    for _, kind in ipairs(catalog.all("items")) do
        if eligible(ctx, player, species, kind, class_id) then
            candidates[#candidates + 1] = kind
        end
    end

    if #candidates == 0 then
        return nil
    end

    return candidates[1 + ctx:random("acquirement", #candidates)]
end

local function append(result, kind, plus, quantity)
    result.kind_ids[#result.kind_ids + 1] = kind.id
    result.pluses[#result.pluses + 1] = plus
    result.quantities[#result.quantities + 1] = quantity
end

function offers.generate(ctx, player)
    local result = {
        kind_ids = {},
        pluses = {},
        quantities = {},
    }

    for _, class_id in ipairs(classes_for(ctx, player)) do
        if #result.kind_ids == 3 then
            break
        end

        local kind = pick_kind(ctx, player, class_id)

        if kind then
            local plus = 0

            if class_id == classes.OBJ_WEAPONS or
                class_id == classes.OBJ_ARMOUR then
                plus = 2 + ctx:random("acquirement", 5)
            end

            if class_id == classes.OBJ_ARMOUR then
                plus = math.min(plus, enchantable.armour_cap(kind))
            end

            append(result, kind, plus, 1)
        end
    end

    local gold = catalog.get("items", item_ids.OBJ_GOLD)
    local quantity = 200 + 2 * ctx:random("acquirement", 601)

    append(result, gold, 0, quantity)

    return result
end

function offers.options(state)
    local options = {}

    for index, kind_id in ipairs(state.kind_ids) do
        local kind = catalog.get("items", kind_id)
        local quantity = state.quantities[index]
        local plus = state.pluses[index]
        local label = items.phrase(kind.name, quantity)

        if plus > 0 then
            label = "+" .. plus .. " " .. label
        end

        options[#options + 1] = {
            id = tostring(index),
            label = label,
        }
    end

    return options
end

function offers.grant(ctx, player, state, index)
    local kind_id = state.kind_ids[index]
    local kind = catalog.get("items", kind_id)
    local item = {
        kind_id = kind_id,
        quantity = state.quantities[index],
        plus = state.pluses[index],
        charges = 0,
        ego = "",
    }

    items.validate(item, kind)

    local entity = ctx:create()
    local position = ctx:get(player, component.POSITION)

    ctx:add(entity, component.ITEM, item)
    ctx:add(entity, component.POSITION, {
        level_id = position.level_id,
        x = position.x,
        y = position.y,
    })

    local identification = require("policy.items.identification")

    identification.reveal_type(ctx, player, entity)
    identification.reveal_item(ctx, entity, {
        type = true,
        pluses = true,
        properties = true,
    })

    return entity
end

return offers
