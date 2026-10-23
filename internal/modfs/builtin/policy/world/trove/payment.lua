-- Theory of operation: a Trove gate stores its price in Akara at
-- population time. This policy reads live inventory, rune progress, and
-- worship at entry, chooses one exact resource, and debits it only inside
-- the staged portal commit. Refusal and inspection change nothing.
-- Example: a modded gate may ask for an identified enchanted weapon by
-- setting item_id, quantity, and minimum_plus in its validated price.
local catalog = require("policy.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local identification = require("policy.items.identification")
local items = require("policy.inventory.items")
local properties = require("policy.items.properties")
local runes = require("policy.character.runes")
local trove = require("constants.trove")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local price_policies = require("policy.world.trove.prices.catalog")

local payment = {}

-- The entrance must display the saved amount and enchantment, because a
-- generic subtype name would conceal what the player must actually pay.
function payment.price_name(gate)
    local custom = price_policies.get(gate.price_kind)

    if custom then
        return custom.name(gate)
    end

    if gate.price_kind == trove.PRICE_NO_PIETY then
        return "all divine favour"
    end

    local kind = catalog.get("items", gate.item_id)

    if gate.price_kind == trove.PRICE_RUNE then
        return "the " .. kind.name
    end

    if gate.item_id == item_ids.MISC_HORN_OF_GERYON then
        return "the horn of Geryon"
    end

    if gate.artefact_name ~= "" then
        return gate.artefact_name
    end

    local name = properties.name(kind, gate.ego_id, kind.name)

    if gate.minimum_plus ~= 0 then
        name = string.format("%+d %s", gate.minimum_plus, name)
    end

    return items.phrase(name, gate.quantity)
end

-- Inspection uses the same saved gate as confirmation; it performs no
-- payment check or roll, so modded prices remain stable on repeated looks.
function payment.describe(gate)
    local custom = price_policies.get(gate.price_kind)

    if custom then
        return custom.describe and custom.describe(gate) or
            "This portal requires " .. custom.name(gate) .. " to enter."
    end

    if gate.price_kind == trove.PRICE_NO_PIETY then
        return "The portal proclaims the material over the divine. " ..
            "Entering it will cost you all favour with your deity."
    end

    if gate.price_kind == trove.PRICE_RUNE then
        return "This portal requires the presence of " ..
            payment.price_name(gate) .. " to function. Show it to enter."
    end

    return "This portal needs " .. payment.price_name(gate) ..
        " to function. Give it to enter."
end

-- Keep one source-style prompt for each price category. The target ID
-- returned to the command layer ties a later confirmation to this gate.
function payment.offer(ctx, gate_entity, gate)
    local target = tostring(ctx:id(gate_entity))
    local custom = price_policies.get(gate.price_kind)

    if custom then
        return {
            target = target,
            prompt = custom.offer and custom.offer(gate) or
                "This trove requires " .. custom.name(gate) ..
                    " to function. Enter?",
        }
    end

    if gate.price_kind == trove.PRICE_NO_PIETY then
        return {
            target = target,
            prompt = "This portal proclaims the superiority of the material " ..
                "over the divine; those who enter it will lose all favour " ..
                "with their deity. Enter anyway?",
        }
    end

    local name = payment.price_name(gate)
    local prefix = gate.price_kind == trove.PRICE_RUNE and
        "This trove requires the presence of " or
        "This trove needs "
    local verb = gate.price_kind == trove.PRICE_RUNE and
        " Show it the item?" or " Give it the item?"

    return {
        target = target,
        prompt = prefix .. name .. " to function." .. verb,
    }
end

-- The source compares known type, properties, and pluses before checking
-- quantity, ego, and artefact identity. A displayed unknown item cannot
-- pay simply because its hidden catalog ID happens to match.
local function qualifies(ctx, player, entity, gate)
    local item = ctx:get(entity, component.ITEM)
    local carrier = ctx:get(entity, component.CARRIED_BY)

    if not item or not carrier or carrier.holder ~= player or
        item.kind_id ~= gate.item_id or
        item.quantity < gate.quantity or
        item.plus < gate.minimum_plus or
        ctx:get(entity, component.EQUIPPED) then
        return false
    end

    local kind = catalog.get("items", item.kind_id)

    -- The source treats miscellaneous prices, notably the horn, as an
    -- identity/plus match without its normal identification requirement.
    if kind.class ~= classes.OBJ_MISCELLANY then
        local known = identification.known(ctx, player, entity)

        if not known.type or not known.properties or not known.pluses then
            return false
        end
    end

    if gate.ego_id ~= "" and item.ego ~= gate.ego_id then
        return false
    end

    if gate.artefact_name ~= "" then
        local artefact = ctx:get(entity, component.ITEM_ARTEFACT)

        if not artefact or artefact.name ~= gate.artefact_name then
            return false
        end
    end

    return true
end

-- Prefer an exact enchantment; otherwise take the least valuable plus
-- that qualifies. For an unenchanted request use inventory query order.
local function choose_item(ctx, player, gate)
    local selected
    local selected_plus

    for _, entity in ipairs(ctx:query({
        component.ITEM,
        component.CARRIED_BY,
    })) do
        if qualifies(ctx, player, entity, gate) then
            local item = ctx:get(entity, component.ITEM)

            if not selected or
                (gate.minimum_plus ~= 0 and
                    (item.plus == gate.minimum_plus or
                        item.plus < selected_plus)) then
                selected = entity
                selected_plus = item.plus

                if item.plus == gate.minimum_plus then
                    break
                end
            end
        end
    end

    return selected
end

-- A rune is proved from player progress, not an inventory item. Ashenzari
-- can refuse a piety Trove after conversion even if it rolled earlier.
function payment.match(ctx, player, gate)
    local custom = price_policies.get(gate.price_kind)

    if custom then
        return custom.match(ctx, player, gate)
    end

    if gate.price_kind == trove.PRICE_NO_PIETY then
        local worship = ctx:get(player, component.RELIGION_WORSHIP)

        if worship and worship.god_id == gods.ASHENZARI then
            return nil, "Ashenzari's curse prevents this portal from opening."
        end

        return { kind = trove.PRICE_NO_PIETY }
    end

    if gate.price_kind == trove.PRICE_RUNE then
        if runes.has(ctx, player, gate.item_id) then
            return {
                kind = trove.PRICE_RUNE,
                item_id = gate.item_id,
            }
        end

        return nil, "You do not have the required rune."
    end

    if gate.price_kind ~= trove.PRICE_ITEM then
        error("Trove gate has an unknown price kind")
    end

    local entity = choose_item(ctx, player, gate)

    if not entity then
        return nil, "You do not have the required identified item to give."
    end

    return {
        kind = trove.PRICE_ITEM,
        entity = entity,
        item_id = gate.item_id,
        quantity = gate.quantity,
    }
end

-- Debit exactly one selected stack after staging has succeeded. The caller
-- stores the receipt on its gate in the same reversible portal transaction.
function payment.commit(ctx, player, gate, accepted)
    if not accepted or accepted.kind ~= gate.price_kind then
        error("Trove payment changed before commit")
    end

    local custom = price_policies.get(gate.price_kind)

    if custom then
        return custom.commit(ctx, player, gate, accepted)
    end

    if gate.price_kind == trove.PRICE_RUNE then
        if not runes.has(ctx, player, gate.item_id) then
            error("Trove rune proof changed before commit")
        end

        return {
            kind = trove.PRICE_RUNE,
            item_id = gate.item_id,
            quantity = 0,
        }
    end

    if gate.price_kind == trove.PRICE_NO_PIETY then
        local worship = ctx:get(player, component.RELIGION_WORSHIP)

        if worship and worship.god_id == gods.ASHENZARI then
            error("Ashenzari blocks this Trove")
        end

        local lost = 0

        if worship and worship.god_id ~= gods.NO_GOD and
            worship.piety > trove.PIETY_AFTER_PAYMENT then
            lost = worship.piety - trove.PIETY_AFTER_PAYMENT
            worship.piety = trove.PIETY_AFTER_PAYMENT
            ctx:set(player, component.RELIGION_WORSHIP, worship)
        end

        return {
            kind = trove.PRICE_NO_PIETY,
            item_id = "",
            quantity = lost,
        }
    end

    if not qualifies(ctx, player, accepted.entity, gate) then
        error("Trove item changed before commit")
    end

    local item = ctx:get(accepted.entity, component.ITEM)

    if item.quantity == gate.quantity then
        ctx:destroy(accepted.entity)
    else
        item.quantity = item.quantity - gate.quantity
        ctx:set(accepted.entity, component.ITEM, item)
    end

    return {
        kind = trove.PRICE_ITEM,
        item_id = item.kind_id,
        quantity = gate.quantity,
    }
end

return payment
