local items = require("policy.inventory.items")
local potions = require("policy.potions")
local player_health = require("policy.combat.player_health")
local forms = require("policy.magic.effects.forms.player")
local potion_rules = require("policy.character.potion_rules")
local item_ids = require("ids.items")
local physiology = require("policy.mutations.physiology")
local intent = require("constants.intent")

local quaff = {}

function quaff.prepare(ctx, player, item_id)
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

    if kind.class ~= "OBJ_POTIONS" then
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

    if not potions[item.kind_id] then
        return {
            message = "That potion's effect is unavailable in the Go port.",
        }
    end

    if item.kind_id == item_ids.POT_MUTATION and
        not physiology.can_safely_mutate(ctx, player) then
        local temporary = physiology.can_safely_mutate(ctx, player, false)

        return {
            message = temporary and "You cannot mutate at present." or
                "You cannot mutate.",
        }
    end

    if item.kind_id == item_ids.POT_HEAL_WOUNDS then
        if not potion_rules.can_heal(ctx, player) then
            return {
                message = "You cannot be healed by potions.",
            }
        end

        if not player_health.can_heal(ctx, player) then
            return {
                message = "You cannot heal while in death's door.",
            }
        end

        local health = ctx:get(player, "core.health")

        if not health then
            error("player has no health for heal wounds")
        end

        if health.current == health.max then
            return {
                message = "Your health is already full.",
            }
        end
    end

    if item.kind_id == item_ids.POT_CURING and
        (not player_health.can_heal(ctx, player) or
            not potion_rules.can_heal(ctx, player)) and
        not ctx:has(player, "core.poison") then
        return {
            message = "You have no ailments to cure.",
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
