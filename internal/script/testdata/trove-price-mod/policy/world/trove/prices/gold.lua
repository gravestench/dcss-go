-- Example sparse mod: a Trove may take gold without replacing the engine's
-- source item, rune, or piety handlers. The existing quantity field stores
-- the gold amount, and the saved receipt records that exact debit.
local component = require("constants.component")
local wallet = require("policy.shops.wallet")

local gold = {
    id = "gold",
}

-- A gold gate has no item identity or enchantment to match.
function gold.valid(price)
    return price.item_id == "" and price.quantity > 0 and
        price.minimum_plus == 0 and price.ego_id == "" and
        price.artefact_name == "" and price.source_rune_index == 0
end

-- The amount on the Akara gate is the same one shown at the entrance.
function gold.name(gate)
    return gate.quantity .. " gold"
end

-- Inspection is free, so it reads the saved price without touching the wallet.
function gold.describe(gate)
    return "This portal requires " .. gold.name(gate) .. " to enter."
end

-- Confirmation binds the displayed amount to the same saved gate.
function gold.offer(gate)
    return "Give " .. gold.name(gate) .. " to enter this trove?"
end

-- Check the live wallet at confirmation; an earlier display proves nothing.
function gold.match(ctx, player, gate)
    if not wallet.can_spend(ctx, player, gate.quantity) then
        return nil, "You do not have enough gold."
    end

    return { kind = gold.id }
end

-- The shared travel transaction calls this only after floor staging succeeds.
function gold.commit(ctx, player, gate, accepted)
    if accepted.kind ~= gold.id then
        error("gold Trove confirmation changed")
    end

    wallet.spend(ctx, player, gate.quantity)

    return {
        kind = gold.id,
        item_id = "",
        quantity = gate.quantity,
    }
end

-- Restore accepts only the amount that the immutable source marker priced.
function gold.valid_receipt(gate)
    return gate.receipt_item_id == "" and
        gate.receipt_quantity == gate.quantity
end

return gold
