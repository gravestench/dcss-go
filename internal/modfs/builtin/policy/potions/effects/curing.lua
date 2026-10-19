local items = require("ids.items")
local potions = require("policy.potions")
local common = require("policy.potions.common")
local health_rules = require("policy.combat.player_health")
local potion_rules = require("policy.character.potion_rules")
local component = require("constants.component")
local zap = require("policy.magic.effects.zaps.ids").component

local effect = {}

-- Poison or confusion makes Curing useful even when ordinary healing is blocked.
function effect.can_quaff(ctx, player)
    if ctx:has(player, component.POISON) or
        ctx:has(player, zap.PLAYER_CONFUSION) then
        return nil
    end

    if not health_rules.can_heal(ctx, player) then
        return "You can't heal while in death's door."
    end

    if not potion_rules.can_heal(ctx, player) then
        return "You have no ailments to cure."
    end
end

-- Source: potion.cc:PotionCuring::effect.
-- Example: Curing removes poison and confusion and can restore a small amount of HP.
function effect.apply(ctx, player)
    local health = common.required(ctx, player, component.HEALTH)

    if health_rules.can_heal(ctx, player) and
        potion_rules.can_heal(ctx, player) then
        local amount = 5 + ctx:random("potion", 7)

        health.current = math.min(health.max,
            health.current + potion_rules.scale_healing(ctx, player, amount))

        ctx:set(player, component.HEALTH, health)
    end

    if ctx:has(player, component.POISON) then
        ctx:remove(player, component.POISON)
    end

    if ctx:has(player, zap.PLAYER_CONFUSION) then
        ctx:remove(player, zap.PLAYER_CONFUSION)
    end

    return "You feel better."
end

potions.register(items.POT_CURING, effect)

return effect
