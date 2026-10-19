local items = require("policy.inventory.items")
local potions = require("policy.potions")
local forms = require("policy.magic.effects.forms.player")
local potion_rules = require("policy.character.potion_rules")
local intent = require("constants.intent")
local item_classes = require("constants.item_classes")

local quaff = {}

-- Quaff preparation checks the item and effect eligibility before the action opens.
-- Example: quaff.prepare(ctx, player, potion_id, false) rejects an unusable carried potion.
function quaff.prepare(ctx, player, item_id, forced)
    local entity = item_id ~= 0 and ctx:entity(item_id) or nil
    local item = entity and ctx:get(entity, "core.item")
    local carrier = entity and ctx:get(entity, "core.carried_by")

    if not item or not carrier or carrier.holder ~= player then
        return {
            message = "You are not carrying that potion.",
        }
    end

    local kind = items.kind(item)
    items.validate(item, kind)

    if kind.class ~= item_classes.POTIONS then
        return {
            message = "You cannot drink that.",
        }
    end

    if not potion_rules.can_drink(ctx, player) then
        return {
            message = "You can't drink.",
        }
    end

    if not forms.can_drink(ctx, player) then
        return {
            message = "You cannot drink in this form.",
        }
    end

    local effect = potions.get(item.kind_id)

    if not effect then
        return {
            message = "That potion's effect is unavailable in the Go port.",
        }
    end

    local refusal, confirmation = effect.can_quaff(ctx, player, forced)

    if refusal then
        return {
            message = refusal,
        }
    end

    if confirmation then
        return {
            confirmation = confirmation,
        }
    end

    return {
        intent = {
            kind = intent.QUAFF,
            item_id = entity,
        },
        cost = 10,
    }
end

return quaff
