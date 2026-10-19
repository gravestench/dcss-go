local items = require("ids.items")
local potions = require("policy.potions")
local common = require("policy.potions.common")
local health_rules = require("policy.combat.player_health")
local potion_rules = require("policy.character.potion_rules")
local component = require("constants.component")

local effect = {}

-- Reject ineffective healing before consumption, including Death's Door and full HP.
-- Example: full HP or Death's Door rejects Heal Wounds before the bottle is spent.
function effect.can_quaff(ctx, player)
    if not potion_rules.can_heal(ctx, player) then
        return "You cannot be healed by potions."
    end

    if not health_rules.can_heal(ctx, player) then
        return "You cannot heal while in death's door."
    end

    local health = common.required(ctx, player, component.HEALTH)

    if health.current == health.max then
        return "Your health is already full."
    end
end

-- Source: potion.cc:PotionHealWounds::effect.
function effect.apply(ctx, player)
    local health = common.required(ctx, player, component.HEALTH)
    local amount = 10 + common.average_three(ctx, 28)

    health.current = math.min(health.max,
        health.current + potion_rules.scale_healing(ctx, player, amount))

    ctx:set(player, component.HEALTH, health)

    return "You feel much better."
end

potions.register(items.POT_HEAL_WOUNDS, effect)

return effect
