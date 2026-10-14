local catalog = require("policy.catalog")
local items = require("policy.inventory.items")
local equipment = require("policy.inventory.equipment")
local fighter = require("policy.combat.fighter")

local armour_slots = {
    body = true,
    shield = true,
    head = true,
    cloak = true,
    gloves = true,
    boots = true,
}

local supported_weapons = {
    SK_SHORT_BLADES = true,
    SK_LONG_BLADES = true,
    SK_MACES_FLAILS = true,
    SK_AXES = true,
    SK_POLEARMS = true,
}

local function held_item(ctx, id, player, slot)
    local number = type(id) == "number" and id or ctx:id(id)
    local entity = number ~= 0 and
        (type(id) == "number" and ctx:entity(id) or id) or nil
    local item = entity and ctx:get(entity, "core.item")
    local carrier = entity and ctx:get(entity, "core.carried_by")

    if not item or not carrier or ctx:id(carrier.holder) ~= ctx:id(player) then
        error("saved equipment delay references missing item " .. number)
    end

    local kind = items.kind(item)

    if kind.slot ~= slot then
        error("saved equipment delay has invalid item " .. number)
    end

    return entity, item, kind
end

local function validate_delay(ctx, player, slots)
    local delay = ctx:get(player, "core.equipment_delay")

    if not delay then
        return
    end

    local item_id = ctx:id(delay.item_id)
    local old_item_id = ctx:id(delay.old_item_id)

    if delay.remaining < 1 or delay.remaining > 5 or
        not armour_slots[delay.slot] or
        (delay.phase ~= "wear" and delay.phase ~= "remove") then
        error("invalid saved equipment delay")
    end

    if (delay.phase == "remove" and delay.remaining == 5) or
        (delay.phase == "wear" and old_item_id == 0 and delay.remaining == 5) then
        error("saved equipment delay has impossible turn count")
    end

    if (delay.phase == "remove" and old_item_id == 0) or
        (delay.phase == "wear" and item_id == 0) then
        error("saved equipment delay lacks its item")
    end

    if item_id ~= 0 and item_id == old_item_id then
        error("saved equipment delay repeats one item")
    end

    local old
    local new
    local new_kind

    if old_item_id ~= 0 then
        old = held_item(ctx, delay.old_item_id, player, delay.slot)
    end

    if item_id ~= 0 then
        new, _, new_kind = held_item(ctx, delay.item_id, player, delay.slot)
    end

    if delay.phase == "remove" then
        local equipped = old and ctx:get(old, "core.equipped")

        if not equipped or equipped.slot ~= delay.slot then
            error("saved removal has no equipped item")
        end
    else
        if ctx:get(new, "core.equipped") then
            error("saved wear item is already equipped")
        end

        if slots[delay.slot] then
            error("saved wear slot is still occupied")
        end
    end

    if new then
        if not new_kind.armour then
            error("saved wear item is not armour")
        end

        local fit = equipment.validate_fit(ctx, player, new_kind)

        if fit then
            error("saved wear item does not fit: " .. fit)
        end
    end
end

local function validate(ctx)
    local player = ctx:player()
    local identity = ctx:get(player, "core.player")
    local species = catalog.get("species", identity.species_id)
    local slots = {}
    local starting_weapon_found = identity.starting_weapon_id == "WPN_UNARMED"

    for _, entity in ipairs(ctx:query({ "core.item" })) do
        local item = ctx:get(entity, "core.item")
        local kind = items.kind(item)
        items.validate(item, kind)
        local carrier = ctx:get(entity, "core.carried_by")
        local equipped = ctx:get(entity, "core.equipped")

        if (kind.class == "OBJ_CORPSES") ~= ctx:has(entity, "core.corpse") then
            error("item " .. ctx:id(entity) .. " has mismatched corpse state")
        end

        if item.kind_id == identity.starting_weapon_id and
            (carrier or ctx:has(entity, "core.position")) then
            starting_weapon_found = true
        end

        if carrier and ctx:id(carrier.holder) == ctx:id(player) and equipped then
            local slot = equipped.slot

            if not kind.slot or kind.slot ~= slot then
                error("item " .. ctx:id(entity) .. " has invalid equipped slot")
            end

            if slots[slot] then
                error("duplicate equipped slot " .. slot)
            end

            slots[slot] = kind.id

            if item.plus < -100 or item.plus > 100 then
                local combat_rule = slot == "weapon" and "attack" or "defense"
                error("unsupported saved player " .. combat_rule .. " enchantment")
            end

            if kind.id == "ARM_BARDING" or kind.id == "ARM_CENTAUR_BARDING" then
                error("item " .. ctx:id(entity) .. " has barding equipped")
            end
        end
    end

    local head = slots.head and catalog.get("items", slots.head)

    if head and head.id == "ARM_HELMET" then
        for _, mutation in ipairs(species.mutations or {}) do
            if mutation.id == "MUT_HORNS" and mutation.level <= 1 and mutation.amount > 0 then
                error("saved helmet conflicts with horns")
            end
        end
    end

    local weapon = slots.weapon and catalog.get("items", slots.weapon)

    if weapon then
        if weapon.class ~= "OBJ_WEAPONS" or not weapon.weapon or
            not supported_weapons[weapon.weapon.skill_id] then
            error("unsupported equipped weapon " .. weapon.id)
        end

        if slots.shield and equipment.needs_second_hand(weapon, species.size) then
            error("equipped weapon " .. weapon.id .. " conflicts with shield")
        end
    end

    validate_delay(ctx, player, slots)

    if not starting_weapon_found then
        error("save is missing selected starting weapon " .. identity.starting_weapon_id)
    end

    fighter.defense(ctx)
    fighter.attack(ctx, { ev = 0, ac = 0 })
end

register.policy({
    id = "save.validate_equipment",
    run = function(ctx)
        validate(ctx)
        return {}
    end,
})
