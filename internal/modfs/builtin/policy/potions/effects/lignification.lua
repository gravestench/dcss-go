local component = require("constants.component")
local items = require("ids.items")
local potions = require("policy.potions")
local forms = require("policy.magic.effects.forms.player")
local cloud = require("policy.clouds.placement")
local cloud_ids = require("ids.clouds")
local zap_ids = require("policy.magic.effects.zaps.ids")

local effect = {}

function effect.cloud_confirmation(ctx, player)
    local position = ctx:get(player, component.POSITION)

    if not position then
        return nil
    end

    local entity = cloud.at(ctx, position.level_id,
        position.x, position.y)

    if not entity then
        return nil
    end

    local state = ctx:get(entity, component.WORLD_CLOUD)

    if state.kind_id == cloud_ids.CLOUD_FIRE or
        state.kind_id == cloud_ids.CLOUD_COLD then
        return "Really become a tree while standing in a damaging cloud?"
    end

    return nil
end

function effect.can_quaff(ctx, player, forced)
    local refusal = forms.rejection(ctx, player, items.POT_LIGNIFY)

    if refusal then
        return refusal
    end

    if not forced then
        local confirmation = effect.cloud_confirmation(ctx, player)

        if confirmation then
            return nil, confirmation
        end
    end

    return nil
end

-- Source: potion.cc:PotionLignify::effect and transform.cc:transform.
function effect.apply(ctx, player)
    forms.cast(ctx, player, items.POT_LIGNIFY, 0)

    local state = ctx:get(player, component.PLAYER_FORM)

    state.uncancellable = true
    ctx:set(player, component.PLAYER_FORM, state)

    return "You turn into a tree."
end

potions.register(items.POT_LIGNIFY, effect)

return effect
