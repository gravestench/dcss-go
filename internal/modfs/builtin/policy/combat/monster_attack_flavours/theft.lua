-- Maurice's Steal contact moves real Akara item entities. Source monster
-- inventory slots constrain candidates; the wallet owns gold balance.
local armour_slots = require("constants.armour_slots")
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local identification = require("policy.items.identification")
local items = require("policy.inventory.items")
local item_ids = require("ids.items")
local object_classes = require("ids.object_classes")
local pricing = require("policy.shops.pricing")
local roll = require("policy.combat.roll")
local size = require("constants.size")
local targets = require("policy.ai.targets")
local tithe_states = require("constants.zin_tithe_state")
local wallet = require("policy.shops.wallet")
local gods = require("constants.gods")

local theft = {}

local class_slots = {
    [object_classes.OBJ_JEWELLERY] = "jewellery",
    [object_classes.OBJ_WANDS] = "wand",
    [object_classes.OBJ_BOOKS] = "scroll",
    [object_classes.OBJ_SCROLLS] = "scroll",
    [object_classes.OBJ_POTIONS] = "potion",
    [object_classes.OBJ_MISCELLANY] = "miscellany",
    [object_classes.OBJ_GOLD] = "gold",
}

-- Source `item_to_mslot` rejects auxiliary armour and every class without
-- a monster inventory slot. Books share Scroll, and staves share Weapon.
local function slot_for(kind)
    local class = kind.class

    if class == object_classes.OBJ_WEAPONS or
        class == object_classes.OBJ_STAVES or
        class == object_classes.OBJ_RODS then
        return "weapon"
    end

    if class == object_classes.OBJ_MISSILES then
        return "missile"
    end

    if class == object_classes.OBJ_ARMOUR then
        if kind.armour and kind.armour.slot_id ==
            armour_slots.BODY_ARMOUR then
            return "body"
        end

        if kind.armour and kind.armour.slot_id ==
            armour_slots.SHIELD then
            return "shield"
        end

        return nil
    end

    return class_slots[class]
end

-- Infer occupied source slots from current carried items rather than
-- maintaining a second inventory record that could drift from ECS links.
local function occupied_slots(ctx, monster)
    local occupied = {}

    for _, entity in ipairs(ctx:query({
        component.ITEM,
        component.CARRIED_BY,
    })) do
        local carrier = ctx:get(entity, component.CARRIED_BY)

        if carrier.holder == monster then
            local item = ctx:get(entity, component.ITEM)
            local kind = catalog.get("items", item.kind_id)
            local equipped = ctx:get(entity, component.EQUIPPED)
            local slot = equipped and equipped.slot or slot_for(kind)

            if slot == "weapon" and occupied.weapon then
                slot = "alternate_weapon"
            end

            if slot then
                occupied[slot] = true
            end
        end
    end

    return occupied
end

-- The currently delayed armour or jewellery action owns its item until
-- the action finishes. Source Maurice cannot snatch an in-use object.
local function in_use(ctx, player, entity)
    local delay = ctx:get(player, component.EQUIPMENT_DELAY)

    return delay ~= nil and
        (delay.item_id == entity or delay.old_item_id == entity)
end

-- Pick a free monster slot before paying for a candidate. A second weapon
-- can use Alternate Weapon; every other source slot has capacity one.
local function open_slot(occupied, kind)
    local slot = slot_for(kind)

    if slot == "weapon" and occupied.weapon then
        slot = "alternate_weapon"
    end

    if not slot or occupied[slot] then
        return nil
    end

    return slot
end

-- Weighted reservoir selection matches source inventory scanning without
-- building a duplicated value table or changing item-order RNG behavior.
local function select_item(ctx, monster, player)
    local occupied = occupied_slots(ctx, monster)
    local total = 0
    local selected

    for _, entity in ipairs(ctx:query({
        component.ITEM,
        component.CARRIED_BY,
    })) do
        local carrier = ctx:get(entity, component.CARRIED_BY)

        if carrier.holder == player and
            not ctx:has(entity, component.EQUIPPED) and
            not in_use(ctx, player, entity) then
            local item = ctx:get(entity, component.ITEM)
            local kind = catalog.get("items", item.kind_id)
            local slot = open_slot(occupied, kind)

            if slot and slot ~= "gold" then
                -- Source item_value(item, true) identifies only the value
                -- calculation, without revealing the item to the player.
                local value = pricing.value(ctx, entity, true)

                total = total + value

                if roll.melee(ctx, total) < value then
                    selected = {
                        entity = entity,
                        slot = slot,
                    }
                end
            end
        end
    end

    return selected
end

-- Copy the instance data that a split stack needs on its new item entity.
-- Nonstackable artefacts and manuals transfer whole and retain identity.
local function split_item(ctx, source, item, amount)
    local stolen = ctx:create()

    ctx:add(stolen, component.ITEM, {
        kind_id = item.kind_id,
        quantity = amount,
        plus = item.plus,
        charges = item.charges,
        ego = item.ego,
    })

    identification.copy(ctx, source, stolen)

    for _, id in ipairs({
        component.ITEM_PROVENANCE,
        component.VAULT_ITEM_APPEARANCE,
    }) do
        local state = ctx:get(source, id)

        if state then
            ctx:add(stolen, id, state)
        end
    end

    item.quantity = item.quantity - amount
    ctx:set(source, component.ITEM, item)

    return stolen
end

-- A weapon above the monster's one-hand size threshold needs both hands.
-- Source NUM_SIZE_LEVELS means no creature can wield it with one hand.
local function needs_two_hands(ctx, monster, kind)
    if kind.class ~= object_classes.OBJ_WEAPONS or
        not kind.weapon then
        return false
    end

    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local monster_size = size.rank[definition.size_id]
    local one_hand_size = size.rank[kind.weapon.min_1h_size_id]

    return monster_size < (one_hand_size or math.huge)
end

-- Source Steal drops the old shield before accepting a two-handed weapon.
-- Use floor and carrier components so defense, death drops, and saves all
-- observe the same equipment transition.
local function release_shield(ctx, monster)
    for _, entity in ipairs(ctx:query({
        component.EQUIPPED,
        component.CARRIED_BY,
    })) do
        local equipped = ctx:get(entity, component.EQUIPPED)
        local carrier = ctx:get(entity, component.CARRIED_BY)

        if carrier.holder == monster and equipped.slot == "shield" then
            ctx:remove(entity, component.EQUIPPED)
            ctx:remove(entity, component.CARRIED_BY)
            ctx:add(entity, component.POSITION,
                ctx:get(monster, component.POSITION))

            return
        end
    end
end

-- Transfer the chosen quantity into Maurice's actual carried inventory.
-- Only slots the current monster combat owner understands become equipped.
local function take_item(ctx, monster, player, selected)
    local source = selected.entity
    local item = ctx:get(source, component.ITEM)
    local kind = catalog.get("items", item.kind_id)
    local amount = 1 + roll.melee(ctx, item.quantity)
    local whole_stack = amount == item.quantity
    local name = identification.name(ctx, player, source)
    local stolen = source

    if (selected.slot == "weapon" or
        selected.slot == "alternate_weapon") and
        needs_two_hands(ctx, monster, kind) then
        release_shield(ctx, monster)
    end

    if not whole_stack then
        stolen = split_item(ctx, source, item, amount)
        ctx:add(stolen, component.CARRIED_BY, {
            holder = monster,
        })
    else
        ctx:set(source, component.CARRIED_BY, {
            holder = monster,
        })
    end

    if selected.slot == "weapon" or
        selected.slot == "alternate_weapon" then
        if kind.class == object_classes.OBJ_WEAPONS then
            ctx:add(stolen, component.EQUIPPED, {
                slot = selected.slot,
            })
        end
    elseif selected.slot == "missile" or
        selected.slot == "body" or selected.slot == "shield" then
        ctx:add(stolen, component.EQUIPPED, {
            slot = selected.slot,
        })
    end

    local plural = items.phrase(name, 2):sub(3)
    local phrase = whole_stack and "your " .. name or
        amount .. " of your " .. plural

    ctx:emit(channels.COMBAT, display.name(ctx, monster) ..
        " steals " .. phrase .. "!")

    return true
end

-- Stolen gold remains a physical carried item. Zin's source tithe marker
-- prevents the same coins from being donated again when recovered.
local function take_gold(ctx, monster, player)
    local balance = ctx:get(player, component.WALLET)

    if not balance or balance.gold <= 0 then
        return false
    end

    local amount = math.min(20 + roll.melee(ctx, 800), balance.gold)
    local pile

    for _, entity in ipairs(ctx:query({
        component.ITEM,
        component.CARRIED_BY,
    })) do
        local carrier = ctx:get(entity, component.CARRIED_BY)
        local item = ctx:get(entity, component.ITEM)

        if carrier.holder == monster and item.kind_id ==
            item_ids.OBJ_GOLD then
            pile = entity
            break
        end
    end

    if pile then
        local item = ctx:get(pile, component.ITEM)

        item.quantity = item.quantity + amount
        ctx:set(pile, component.ITEM, item)
    else
        pile = ctx:create()
        ctx:add(pile, component.ITEM, {
            kind_id = item_ids.OBJ_GOLD,
            quantity = amount,
            plus = 0,
            charges = 0,
            ego = "",
        })
        ctx:add(pile, component.CARRIED_BY, {
            holder = monster,
        })
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local state = worship and worship.god_id == gods.ZIN and
        tithe_states.NO_TITHE or tithe_states.NO_PIETY
    local metadata = {
        state = state,
        acquired = false,
    }

    if ctx:has(pile, component.GOLD_TITHE) then
        ctx:set(pile, component.GOLD_TITHE, metadata)
    else
        ctx:add(pile, component.GOLD_TITHE, metadata)
    end

    local remaining = wallet.steal(ctx, player, amount)

    local suffix = amount == 1 and "" or "s"

    ctx:emit(channels.COMBAT, display.name(ctx, monster) ..
        " steals " .. amount .. " gold piece" .. suffix .. "!")
    local remaining_suffix = remaining == 1 and "" or "s"

    ctx:emit(channels.COMBAT, "You now have " ..
        remaining .. " gold piece" .. remaining_suffix .. ".")

    return true
end

-- The source allows Steal only against the player after an actual contact.
-- Gold fallback occurs if no item qualifies or a one-in-ten roll succeeds.
function theft.apply(ctx, hit)
    if hit.kind ~= "hit" or
        not ctx:has(hit.defender, component.PLAYER) then
        return false
    end

    local confusion = ctx:get(hit.attacker,
        component.MONSTER_CONFUSION)

    if confusion and confusion.remaining_aut > 0 or
        targets.real_attitude(ctx, hit.attacker) ~= attitudes.HOSTILE then
        return false
    end

    local selected = select_item(ctx, hit.attacker, hit.defender)
    local balance = ctx:get(hit.defender, component.WALLET)

    if balance and balance.gold > 0 and
        (not selected or roll.melee(ctx, 10) == 0) then
        return take_gold(ctx, hit.attacker, hit.defender)
    end

    if selected then
        return take_item(ctx, hit.attacker, hit.defender, selected)
    end

    return false
end

return theft
