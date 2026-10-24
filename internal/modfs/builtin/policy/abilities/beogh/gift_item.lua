-- Theory of operation: Give Item is one free follower choice followed by
-- one free inventory choice. The player ECS component anchors the first
-- choice across a saved prompt. The timed intent revalidates both entities
-- before transferring the existing item entity to the follower's inventory.
local abilities = require("ids.abilities")
local attitudes = require("constants.attitude")
local armour_slots = require("constants.armour_slots")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local costs = require("policy.abilities.beogh.costs")
local display = require("policy.combat.monster_support.display")
local gift_categories = require("constants.beogh_gift_categories")
local identification = require("policy.items.identification")
local object_classes = require("ids.object_classes")
local monster_slots = require("constants.monster_equipment_slots")
local monster_flags = require("constants.monster_flags")
local registry = require("policy.abilities.registry")
local selection_kinds = require("constants.selection_kinds")
local sizes = require("constants.size")
local skills = require("ids.skills")

local gift_item = {}

-- The five-star menu row follows live worship and Beogh penance.
local function available(ctx, player)
    return costs.available(ctx, player, 5)
end

-- Source is_named includes both bestowed proper names and unique orcs.
-- Looking up the immutable catalog flag avoids copying a displayed name
-- into a second mutable field merely to make a unique eligible.
local function named(ctx, entity)
    local authored = ctx:get(entity,
        component.VAULT_ACTOR_OVERRIDES)

    if authored and authored.custom_name ~= "" then
        return true
    end

    local actor = ctx:get(entity, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get(categories.MONSTERS,
        actor.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == monster_flags.UNIQUE then
            return true
        end
    end

    return false
end

-- Only a visible, living, named god gift can receive a personal gift.
-- A custom name is stored on the actor, never inferred from display text.
function gift_item.follower(ctx, player, entity)
    local source = ctx:get(player, component.POSITION)
    local target = entity and ctx:get(entity, component.POSITION)
    local state = entity and ctx:get(entity, component.BEOGH_ORC)
    local health = entity and ctx:get(entity, component.HEALTH)

    return source ~= nil and target ~= nil and
        source.level_id == target.level_id and
        health ~= nil and health.current > 0 and
        state ~= nil and state.gift and
        state.attitude == attitudes.FRIENDLY and
        state.gift_category == "" and
        named(ctx, entity) and
        ctx:visible_no_trans(source.level_id, source.x, source.y,
            7, target.x, target.y)
end

-- Source inventory selection accepts only a weapon, body armour, or
-- shield. The player must unequip it before offering it to an orc.
local function category(kind)
    if kind.class == object_classes.OBJ_WEAPONS then
        if kind.weapon and kind.weapon.skill_id ==
            skills.SK_RANGED_WEAPONS then
            return gift_categories.RANGED_WEAPON
        end

        return gift_categories.MELEE_WEAPON
    end

    if kind.class == object_classes.OBJ_ARMOUR and kind.armour then
        if kind.armour.slot_id == armour_slots.SHIELD then
            return gift_categories.SHIELD
        end

        if kind.armour.slot_id == armour_slots.BODY_ARMOUR then
            return gift_categories.BODY_ARMOUR
        end
    end

    return nil
end

-- Orcs in this source catalog use a medium body. Check item sizes here
-- because the player equipment policy checks the player's anatomy.
local function fits(kind, gift_category)
    local medium = sizes.rank[sizes.MEDIUM]

    if gift_category == gift_categories.MELEE_WEAPON or
        gift_category == gift_categories.RANGED_WEAPON then
        return kind.weapon and
            medium >= sizes.rank[kind.weapon.min_2h_size_id]
    end

    if gift_category == gift_categories.BODY_ARMOUR then
        return medium >= sizes.rank[kind.armour.fit_min_id] and
            medium <= sizes.rank[kind.armour.fit_max_id]
    end

    return gift_category == gift_categories.SHIELD
end

-- Resolution repeats this ownership check so a stale selection cannot
-- transfer a dropped, destroyed, or incompatible item.
function gift_item.eligible_item(ctx, player, entity)
    local item = entity and ctx:get(entity, component.ITEM)
    local carrier = entity and ctx:get(entity, component.CARRIED_BY)

    if not item or not carrier or carrier.holder ~= player or
        item.quantity ~= 1 or ctx:has(entity, component.EQUIPPED) then
        return false
    end

    local kind = catalog.get(categories.ITEMS, item.kind_id)
    local chosen = category(kind)

    return chosen ~= nil and fits(kind, chosen)
end

-- A shield cannot be handed to an orc wielding a two-handed weapon.
-- Conversely a two-handed gift cannot fit beside its current shield.
local function compatible(ctx, player, follower, item)
    if not gift_item.eligible_item(ctx, player, item) then
        return false
    end

    local source = ctx:get(item, component.ITEM)
    local kind = catalog.get(categories.ITEMS, source.kind_id)
    local chosen = category(kind)
    local shield_held = false
    local two_handed = false

    for _, held in ipairs(ctx:query({ component.CARRIED_BY })) do
        local carrier = ctx:get(held, component.CARRIED_BY)
        local equipped = ctx:get(held, component.EQUIPPED)

        if carrier.holder == follower and equipped then
            if equipped.slot == monster_slots.SHIELD then
                shield_held = true
            elseif equipped.slot == monster_slots.WEAPON or
                equipped.slot == monster_slots.ALTERNATE_WEAPON then
                local worn = ctx:get(held, component.ITEM)
                local definition = catalog.get(categories.ITEMS,
                    worn.kind_id)

                if definition.weapon and sizes.rank[sizes.MEDIUM] <
                    sizes.rank[definition.weapon.min_1h_size_id] then
                    two_handed = true
                end
            end
        end
    end

    if chosen == gift_categories.SHIELD then
        return not two_handed
    end

    if chosen == gift_categories.MELEE_WEAPON or
        chosen == gift_categories.RANGED_WEAPON then
        local gift_two_handed = sizes.rank[sizes.MEDIUM] <
            sizes.rank[kind.weapon.min_1h_size_id]

        return not (gift_two_handed and shield_held)
    end

    return true
end

-- A generic offer menu carries stable entity IDs rather than display
-- names, which may change as mods rename a monster or an item.
local function followers_prompt(ctx, player)
    local options = {}

    for _, entity in ipairs(ctx:query({ component.BEOGH_ORC })) do
        if gift_item.follower(ctx, player, entity) then
            options[#options + 1] = {
                id = tostring(ctx:id(entity)),
                label = display.name(ctx, entity),
            }
        end
    end

    if #options == 0 then
        return { message = "No worthy followers in sight." }
    end

    return {
        selection = {
            kind = selection_kinds.OFFER,
            title = "Select a follower to give a gift to",
            options = options,
        },
    }
end

-- The second prompt includes only the player's qualifying item entities.
local function items_prompt(ctx, player, follower)
    local options = {}

    for _, entity in ipairs(ctx:query({ component.ITEM })) do
        if compatible(ctx, player, follower, entity) then
            options[#options + 1] = {
                id = tostring(ctx:id(entity)),
                label = identification.name(ctx, player, entity),
            }
        end
    end

    if #options == 0 then
        ctx:remove(player, component.BEOGH_GIFT_CHOICE)

        return { message = "You have nothing suitable to give." }
    end

    return {
        selection = {
            kind = selection_kinds.ITEM,
            title = "Give which item?",
            options = options,
        },
    }
end

-- Clear saved selection on escape; no world time or item changes occur.
function gift_item.prepare(ctx, player, input)
    if input.cancelled then
        if ctx:has(player, component.BEOGH_GIFT_CHOICE) then
            ctx:remove(player, component.BEOGH_GIFT_CHOICE)
        end

        return "Okay."
    end

    local pending = ctx:get(player, component.BEOGH_GIFT_CHOICE)
    local selected_id = tonumber(input.target_id)
    local selected = selected_id and ctx:entity(selected_id)

    if pending then
        if not gift_item.follower(ctx, player, pending.follower) then
            ctx:remove(player, component.BEOGH_GIFT_CHOICE)

            return "That follower is no longer here."
        end

        if not selected then
            return items_prompt(ctx, player, pending.follower)
        end

        if not compatible(ctx, player, pending.follower, selected) then
            return "You can't give that item."
        end

        input.item_id = ctx:id(selected)

        return nil
    end

    if not selected then
        return followers_prompt(ctx, player)
    end

    if not gift_item.follower(ctx, player, selected) then
        return "That orc has not proved worthy of your gift."
    end

    ctx:add(player, component.BEOGH_GIFT_CHOICE, {
        follower = selected,
    })

    return items_prompt(ctx, player, selected)
end

-- Replaced gear becomes a floor item at the follower's current cell.
-- Its entity ID and identity are preserved through that transfer.
local function release_slot(ctx, follower, slot)
    for _, entity in ipairs(ctx:query({ component.CARRIED_BY })) do
        local carrier = ctx:get(entity, component.CARRIED_BY)
        local equipped = ctx:get(entity, component.EQUIPPED)

        if carrier.holder == follower and equipped and
            equipped.slot == slot then
            ctx:remove(entity, component.EQUIPPED)
            ctx:remove(entity, component.CARRIED_BY)
            ctx:add(entity, component.POSITION,
                ctx:get(follower, component.POSITION))
        end
    end
end

-- The source keeps opposite weapon modes in separate slots. Giving a
-- ranged weapon to a melee orc (or vice versa) uses alternate_weapon.
local function destination(ctx, follower, chosen)
    if chosen == gift_categories.BODY_ARMOUR then
        return monster_slots.BODY
    end

    if chosen == gift_categories.SHIELD then
        return monster_slots.SHIELD
    end

    for _, entity in ipairs(ctx:query({ component.CARRIED_BY })) do
        local carrier = ctx:get(entity, component.CARRIED_BY)
        local equipped = ctx:get(entity, component.EQUIPPED)

        if carrier.holder == follower and equipped and
            equipped.slot == monster_slots.WEAPON then
            local held = ctx:get(entity, component.ITEM)
            local kind = catalog.get(categories.ITEMS, held.kind_id)

            if category(kind) ~= chosen then
                return monster_slots.ALTERNATE_WEAPON
            end
        end
    end

    return monster_slots.WEAPON
end

-- Source swaps a newly gifted alternate weapon into the wielded slot.
-- The previous main weapon becomes the alternate without changing IDs.
local function promote_alt(ctx, follower, gift)
    local previous

    for _, entity in ipairs(ctx:query({ component.CARRIED_BY })) do
        local carrier = ctx:get(entity, component.CARRIED_BY)
        local equipped = ctx:get(entity, component.EQUIPPED)

        if carrier.holder == follower and equipped and
            equipped.slot == monster_slots.WEAPON then
            previous = entity

            break
        end
    end

    if previous then
        ctx:set(previous, component.EQUIPPED, {
            slot = monster_slots.ALTERNATE_WEAPON,
        })
    end

    ctx:set(gift, component.EQUIPPED, {
        slot = monster_slots.WEAPON,
    })
end

-- One successful timed intent transfers ownership and marks the orc.
-- Rechecking prevents a crafted intent from gifting an unrelated entity.
function gift_item.resolve(ctx, player, intent)
    local pending = ctx:get(player, component.BEOGH_GIFT_CHOICE)
    local follower = pending and pending.follower
    local item = intent.item_id

    if not gift_item.follower(ctx, player, follower) or
        not compatible(ctx, player, follower, item) then
        error("invalid Beogh gift intent")
    end

    local source = ctx:get(item, component.ITEM)
    local kind = catalog.get(categories.ITEMS, source.kind_id)
    local chosen = category(kind)
    local slot = destination(ctx, follower, chosen)

    release_slot(ctx, follower, slot)
    ctx:remove(item, component.EQUIPPED)
    ctx:set(item, component.CARRIED_BY, { holder = follower })
    ctx:add(item, component.EQUIPPED, { slot = slot })

    if slot == monster_slots.ALTERNATE_WEAPON then
        promote_alt(ctx, follower, item)
    end

    local state = ctx:get(follower, component.BEOGH_ORC)

    state.gift_category = chosen
    ctx:set(follower, component.BEOGH_ORC, state)
    ctx:remove(player, component.BEOGH_GIFT_CHOICE)
    ctx:emit("religion", "You give " .. display.name(ctx, follower) ..
        " a gift.")
end

-- Restore rejects missing or disloyal targets before resuming the prompt.
function gift_item.validate(ctx, player)
    local pending = ctx:get(player, component.BEOGH_GIFT_CHOICE)

    if pending and (not costs.available(ctx, player, 5) or
        not gift_item.follower(ctx, player, pending.follower)) then
        error("invalid saved Beogh gift choice")
    end
end

registry.add(abilities.BEOGH_GIFT_ITEM, {
    name = "Give Item to Named Follower",
    available = available,
    owns_cancellation = true,
    prepare = gift_item.prepare,
    resolve = gift_item.resolve,
})

return gift_item
