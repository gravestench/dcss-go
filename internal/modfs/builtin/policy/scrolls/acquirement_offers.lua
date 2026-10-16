-- Source: crawl-ref/source/acquire.cc:shuffled_acquirement_classes and
-- acquirement_menu. Each offer is a real, reserved ECS item.
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local component = require("constants.component")
local equipment = require("policy.inventory.equipment")
local generation = require("policy.item_generation")
local history = require("policy.item_generation.artefacts.history")
local item_ids = require("ids.items")
local items = require("policy.inventory.items")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local quality = require("constants.vault_item_quality")
local purpose = require("constants.item_generation_purpose")
local streams = require("constants.rng_streams")
local armour = require("policy.scrolls.acquirement.armour")
local weapons = require("policy.scrolls.acquirement.weapons")
local accessories = require("policy.scrolls.acquirement.accessories")
local books = require("policy.scrolls.acquirement.books")
local selection = require("policy.scrolls.acquirement.selection")
local source = require("policy.item_generation.source_roll")
local random_artefact = require("policy.item_generation.artefacts.random")
local post_roll = require("policy.scrolls.acquirement.post_roll")

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
        local other = 1 + ctx:random(streams.ACQUIREMENT, index)

        choices[index], choices[other] = choices[other], choices[index]
    end

    return choices
end

local function compatible(ctx, player, species, rolled, class_id)
    local kind = catalog.get("items", rolled.kind_id)

    if kind.class ~= class_id then
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

local subtype_picker = {
    [classes.OBJ_ARMOUR] = armour.pick,
    [classes.OBJ_WEAPONS] = weapons.pick,
    [classes.OBJ_STAVES] = accessories.staff,
    [classes.OBJ_JEWELLERY] = accessories.jewellery,
    [classes.OBJ_BOOKS] = books.pick,
}

local function roll_class(ctx, player, scroll, class_id, depth)
    local choice = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", choice.species_id)

    for _ = 1, 40 do
        local kind_id, extra = subtype_picker[class_id](ctx, player, depth)
        local request = {
            class_id = class_id,
            kind_id = kind_id,
            depth = depth,
            quality = quality.GOOD,
            allow_uniques = true,
            purpose = purpose.ACQUIREMENT,
            site = "acquirement scroll " .. ctx:id(scroll),
        }

        for key, value in pairs(extra or {}) do
            request[key] = value
        end

        local rolled = generation.roll(ctx, request)

        post_roll.adjust(ctx, rolled, depth)

        if class_id == classes.OBJ_JEWELLERY and
            not rolled.components[component.ITEM_ARTEFACT] and
            source.chance(ctx, 1, 2) then
            random_artefact.apply(ctx, catalog.get("items", rolled.kind_id),
                rolled)
        end

        local seen_plain_armour = class_id == classes.OBJ_ARMOUR and
            not rolled.components[component.ITEM_ARTEFACT] and
            selection.seen(ctx, player, rolled.kind_id) and
            source.chance(ctx, 2, 3)

        if compatible(ctx, player, species, rolled, class_id) and
            not seen_plain_armour then
            return rolled
        end

        local artefact = rolled.components[component.ITEM_ARTEFACT]

        if artefact and artefact.unique_id ~= "" then
            history.release(ctx, player, artefact.unique_id)
        end
    end

    error("acquirement scroll " .. ctx:id(scroll) ..
        " could not generate compatible " .. class_id)
end

local function reserve(ctx, scroll, rolled)
    return generation.create(ctx, rolled, {
        reservation = scroll,
    })
end

function offers.generate(ctx, player, scroll)
    local position = ctx:get(player, component.POSITION)
    local state = {
        offer_ids = {},
    }

    for _, class_id in ipairs(classes_for(ctx, player)) do
        if #state.offer_ids == 3 then
            break
        end

        local rolled = roll_class(ctx, player, scroll, class_id,
            position.level_id)

        state.offer_ids[#state.offer_ids + 1] = reserve(ctx, scroll, rolled)
    end

    local gold = generation.roll(ctx, {
        kind_id = item_ids.OBJ_GOLD,
        depth = position.level_id,
        quality = quality.GOOD,
        allow_uniques = false,
        purpose = purpose.ACQUIREMENT,
        site = "acquirement gold " .. ctx:id(scroll),
    })

    state.offer_ids[#state.offer_ids + 1] = reserve(ctx, scroll, gold)

    return state
end

local function label(ctx, entity)
    local item = ctx:get(entity, component.ITEM)

    if not item then
        error("acquirement offer has no item")
    end

    local artefact = ctx:get(entity, component.ITEM_ARTEFACT)

    if artefact then
        return artefact.name
    end

    local kind = catalog.get("items", item.kind_id)
    local label = items.phrase(kind.name, item.quantity)

    if item.plus > 0 then
        label = "+" .. item.plus .. " " .. label
    end

    return label
end

function offers.options(ctx, _, state)
    local options = {}

    for index, entity in ipairs(state.offer_ids) do
        options[#options + 1] = {
            id = tostring(index),
            label = label(ctx, entity),
        }
    end

    return options
end

local function retire(ctx, player, entity)
    local artefact = ctx:get(entity, component.ITEM_ARTEFACT)

    if artefact and artefact.unique_id ~= "" then
        history.release(ctx, player, artefact.unique_id)
    end

    ctx:destroy(entity)
end

function offers.grant(ctx, player, state, index)
    local selected = state.offer_ids[index]
    local reservation = selected and ctx:get(selected, component.RESERVED_BY)

    if not reservation then
        error("acquirement selected offer is no longer reserved")
    end

    for other_index, entity in ipairs(state.offer_ids) do
        if other_index ~= index then
            retire(ctx, player, entity)
        end
    end

    local position = ctx:get(player, component.POSITION)

    ctx:remove(selected, component.RESERVED_BY)
    ctx:add(selected, component.POSITION, {
        level_id = position.level_id,
        x = position.x,
        y = position.y,
    })

    local identification = require("policy.items.identification")

    identification.reveal_type(ctx, player, selected)
    identification.reveal_item(ctx, selected, {
        type = true,
        pluses = true,
        properties = true,
    })

    return selected
end

return offers
