-- Source: crawl-ref/source/acquire.cc:shuffled_acquirement_classes and
-- acquirement_menu. Each offer is a real, reserved ECS item.
local catalog = require("policy.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local component = require("constants.component")
local equipment = require("policy.inventory.equipment")
local generation = require("policy.item_generation")
local gods = require("constants.gods")
local history = require("policy.item_generation.artefacts.history")
local item_ids = require("ids.items")
local items = require("policy.inventory.items")
local usefulness = require("policy.item_generation.usefulness")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local quality = require("constants.vault_item_quality")
local purpose = require("constants.item_generation_purpose")
local streams = require("constants.rng_streams")
local weapon_brands = require("constants.weapon_brands")
local armour = require("policy.scrolls.acquirement.armour")
local weapons = require("policy.scrolls.acquirement.weapons")
local accessories = require("policy.scrolls.acquirement.accessories")
local books = require("policy.scrolls.acquirement.books")
local missiles = require("policy.scrolls.acquirement.missiles")
local wands = require("policy.scrolls.acquirement.wands")
local selection = require("policy.scrolls.acquirement.selection")
local source = require("policy.item_generation.source_roll")
local random_artefact = require("policy.item_generation.artefacts.random")
local post_roll = require("policy.scrolls.acquirement.post_roll")

local offers = {}

local trog_brands = {
    weapon_brands.NORMAL,
    weapon_brands.VORPAL,
    weapon_brands.FLAMING,
    weapon_brands.ANTIMAGIC,
}

local class_choices = {
    classes.OBJ_ARMOUR,
    classes.OBJ_WEAPONS,
    classes.OBJ_STAVES,
    classes.OBJ_JEWELLERY,
    classes.OBJ_BOOKS,
}

-- Remove armour or grasp-dependent classes when mutations forbid them, then shuffle remaining classes.
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

-- Reject a rolled class mismatch or unusable item before reserving a menu offer.
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
            equipment.weapon_supported(kind.weapon.skill_id) and
            equipment.can_wield(ctx, player, species, kind)
    end

    return true
end

local subtype_picker = {
    [classes.OBJ_ARMOUR] = armour.pick,
    [classes.OBJ_WEAPONS] = weapons.pick,
    [classes.OBJ_STAVES] = accessories.staff,
    [classes.OBJ_JEWELLERY] = accessories.jewellery,
    [classes.OBJ_BOOKS] = books.pick,
    [classes.OBJ_WANDS] = wands.pick,
    [classes.OBJ_MISSILES] = missiles.pick,
}

-- Source acquirement retries gifts that cannot be used. Trog also rejects
-- his own named unique rather than handing the player Wrath of Trog.
local function divine_eligible(ctx, player, rolled, god_id)
    if not god_id then
        return true
    end

    if not usefulness.eligible(ctx, player, rolled) then
        return false
    end

    local artefact = rolled.components[component.ITEM_ARTEFACT]

    return not (god_id == gods.TROG and artefact and
        artefact.unique_id == artefact_ids.UNRAND_TROG)
end

-- Only Sif changes book subtype selection; all other classes use the
-- acquirement selector already shared with scrolls and vault rewards.
local function picker_for(class_id, god_id)
    if god_id and class_id == classes.OBJ_BOOKS then
        return books.pick_gift
    end

    return subtype_picker[class_id]
end

-- A direct gift needs source identity all the way through generation.
-- Scroll offers keep their existing acquirement purpose and unique gate.
local function request_for(ctx, class_id, kind_id, depth, site, god_id,
    extra)
    local allow_uniques = god_id ~= gods.SIF_MUNA

    -- Trog suppresses artefact generation on two out of three attempts.
    -- Sample per attempt, as source acquirement does inside its retry loop.
    if god_id == gods.TROG then
        allow_uniques = source.chance(ctx, 1, 3)
    end

    local request = {
        class_id = class_id,
        kind_id = kind_id,
        depth = depth,
        quality = god_id and quality.GIFT or quality.GOOD,
        -- Source book acquirement starts with a plain placeholder and
        -- chooses its themed or level randart after subtype selection.
        allow_uniques = allow_uniques,
        purpose = god_id and purpose.GOD_GIFT or purpose.ACQUIREMENT,
        god_id = god_id,
        site = site,
    }

    for key, value in pairs(extra or {}) do
        request[key] = value
    end

    return request
end

-- Source direct gifts keep their own brand and stack behavior. Scroll
-- acquirement still improves weak weapon brands through post_roll.
local function adjust_rolled(ctx, rolled, class_id, depth, god_id)
    if not god_id then
        post_roll.adjust(ctx, rolled, depth)
    end

    if god_id == gods.TROG and
        class_id == classes.OBJ_WEAPONS and
        not rolled.components[component.ITEM_ARTEFACT] then
        rolled.ego = trog_brands[
            ctx:random(streams.ITEM_GENERATION, #trog_brands) + 1]
        rolled.plus = math.max(0, rolled.plus) +
            ctx:random(streams.ITEM_GENERATION, 3)
    elseif god_id and
        (class_id == classes.OBJ_WEAPONS or
            class_id == classes.OBJ_ARMOUR) then
        rolled.plus = math.max(0, rolled.plus)
    end

    if god_id and class_id == classes.OBJ_MISSILES then
        rolled.quantity = math.max(1,
            math.floor(rolled.quantity / 2))
    end

    if class_id == classes.OBJ_JEWELLERY and
        not rolled.components[component.ITEM_ARTEFACT] and
        source.chance(ctx, 1, 2) then
        random_artefact.apply(ctx, catalog.get("items", rolled.kind_id),
            rolled)
    end
end

-- Scrolls strongly deprioritize a previously seen plain armour subtype;
-- divine gifts have a different source retry policy.
local function seen_plain_armour(ctx, player, rolled, class_id, god_id)
    return not god_id and class_id == classes.OBJ_ARMOUR and
        not rolled.components[component.ITEM_ARTEFACT] and
        selection.seen(ctx, player, rolled.kind_id) and
        source.chance(ctx, 2, 3)
end

-- Rejected offers release a claimed unique artefact before retrying, so another class may still roll it.
-- Retry incompatible rolls and release unique artefact claims so rejected items cannot consume uniques.
local function roll_class(ctx, player, site, class_id, depth, god_id)
    local choice = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", choice.species_id)
    local picker = picker_for(class_id, god_id)

    for _ = 1, 40 do
        local kind_id, extra = picker(ctx, player, depth, god_id)

        if not kind_id then
            return nil
        end

        local request = request_for(ctx, class_id, kind_id,
            depth, site, god_id, extra)
        local rolled = generation.roll(ctx, request)

        adjust_rolled(ctx, rolled, class_id, depth, god_id)

        if compatible(ctx, player, species, rolled, class_id) and
            divine_eligible(ctx, player, rolled, god_id) and
            not seen_plain_armour(ctx, player, rolled,
                class_id, god_id) then
            return rolled
        end

        local artefact = rolled.components[component.ITEM_ARTEFACT]

        if artefact and artefact.unique_id ~= "" then
            history.release(ctx, player, artefact.unique_id)
        end
    end

    if god_id then
        return nil
    end

    error(site .. " could not generate compatible " .. class_id)
end

-- A god requests one direct acquisition result. Its source identity stays
-- in the roll so names and unique history distinguish gifts from scrolls.
function offers.roll_for_gift(ctx, class_id, depth, god_id)
    if not subtype_picker[class_id] then
        error("unsupported god gift class " .. tostring(class_id))
    end

    local player = ctx:player()

    -- A source gift can fail after choosing a class. Check hard anatomy
    -- exclusions before a picker with an empty candidate pool would error.
    if class_id == classes.OBJ_WEAPONS and
        mutation_levels.effective(ctx, player,
            mutations.MUT_NO_GRASPING) > 0 then
        return nil
    end

    if class_id == classes.OBJ_ARMOUR and
        mutation_levels.effective(ctx, player,
            mutations.MUT_NO_ARMOUR) > 0 then
        return nil
    end

    local site = "gift from " .. god_id .. " at depth " .. depth

    return roll_class(ctx, player, site, class_id, depth, god_id)
end

-- A DES `acquire` request uses the same class picker and post-roll policy
-- as a scroll offer, but places its one result directly on a vault floor.
-- This keeps source Trove rewards sensitive to the live character's skills.
function offers.roll_for_vault(ctx, class_id, depth, site)
    if not subtype_picker[class_id] then
        error(site .. " has no acquirement class " .. tostring(class_id))
    end

    return roll_class(ctx, ctx:player(), site, class_id, depth)
end

-- Create the rolled item under scroll reservation; it must not appear on the floor before choice.
local function reserve(ctx, scroll, rolled)
    return generation.create(ctx, rolled, {
        reservation = scroll,
    })
end

-- Example: reading an acquirement scroll reserves three class offers plus gold as real item entities.
-- Generate three shuffled class offers and a gold fallback, preserving real item identities for the menu.
function offers.generate(ctx, player, scroll)
    local position = ctx:get(player, component.POSITION)
    local state = {
        offer_ids = {},
    }

    for _, class_id in ipairs(classes_for(ctx, player)) do
        if #state.offer_ids == 3 then
            break
        end

        local rolled = roll_class(ctx, player,
            "acquirement scroll " .. ctx:id(scroll), class_id,
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

-- Format the reserved entity from artefact name or quantity and pluses for a stable menu label.
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

-- Use one-based offer indices as menu IDs while retaining reserved entity IDs in state.
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

-- Release an unchosen unique claim before destroying its reserved item.
local function retire(ctx, player, entity)
    local artefact = ctx:get(entity, component.ITEM_ARTEFACT)

    if artefact and artefact.unique_id ~= "" then
        history.release(ctx, player, artefact.unique_id)
    end

    ctx:destroy(entity)
end

-- Destroy every unchosen offer, then unreserve and identify the selected item at the player position.
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
