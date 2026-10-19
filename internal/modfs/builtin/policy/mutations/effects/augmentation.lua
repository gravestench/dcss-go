local capabilities = require("constants.mutation_capabilities")
local component = require("constants.component")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")

local augmentation = {}

-- Source: mutation.cc:augmentation_amount counts thresholds from current
-- HP. Each tier is lost as health drops; spell and melee rules share it.
-- Example: low HP can remove an Augmentation tier without removing the mutation record.
function augmentation.amount(level, ctx, player)
    local health = ctx:get(player, component.HEALTH)

    if not health or health.max <= 0 then
        return 0
    end

    local amount = 0

    for tier = 0, level - 1 do
        local threshold = math.floor(
            (tier + level) * health.max / (2 * level))

        if health.current >= threshold then
            amount = amount + 1
        end
    end

    return amount
end

effects.add(mutations.MUT_AUGMENTATION, {
    [capabilities.AUGMENTATION] = augmentation.amount,
})

return augmentation
