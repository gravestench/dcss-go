local items = require("ids.items")
local potions = require("policy.potions")
local common = require("policy.potions.common")
local component = require("constants.component")
local capabilities = require("constants.mutation_capabilities")
local mutations = require("policy.mutations.effects.registry")

local effect = {}

function effect.can_quaff(ctx, player)
    local magic = common.required(ctx, player, component.MAGIC)

    if magic.current == magic.max then
        if magic.max == 0 then
            return "You have no magic to restore."
        end

        return "Your magic is already full."
    end
end

-- Source: defines.h:POT_MAGIC_MP and potion.cc:PotionMagic::effect.
function effect.apply(ctx, player)
    local magic = common.required(ctx, player, component.MAGIC)
    local restored = 10 + common.average_three(ctx, 28)

    magic.current = math.min(magic.max, magic.current + restored)

    ctx:set(player, component.MAGIC, magic)

    if mutations.sum(ctx, player, capabilities.HP_CASTING) > 0 then
        return "Magic washes over you without effect."
    end

    return "Magic courses through your body."
end

potions.register(items.POT_MAGIC, effect)

return effect
