local capabilities = require("constants.mutation_capabilities")
local mutation_effects = require("policy.mutations.effects.registry")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local jewellery_capabilities = require("constants.jewellery_capabilities")

local attributes = {}

local maximum = 125

function attributes.current(ctx, player)
    local base = ctx:get(player, "core.attributes")

    if not base then
        error("player lacks base attributes")
    end

    return {
        strength = math.max(0, math.min(maximum, base.strength -
            stat_loss.amount(ctx, player, stats.STRENGTH) +
            mutation_effects.base_sum(ctx, player,
                capabilities.STRENGTH) +
            jewellery_effects.sum(ctx, player,
                jewellery_capabilities.STRENGTH))),
        intelligence = math.max(0, math.min(maximum, base.intelligence -
            stat_loss.amount(ctx, player, stats.INTELLIGENCE) +
            mutation_effects.base_sum(ctx, player,
                capabilities.INTELLIGENCE) +
            jewellery_effects.sum(ctx, player,
                jewellery_capabilities.INTELLIGENCE))),
        dexterity = math.max(0, math.min(maximum, base.dexterity -
            stat_loss.amount(ctx, player, stats.DEXTERITY) +
            mutation_effects.base_sum(ctx, player,
                capabilities.DEXTERITY) +
            jewellery_effects.sum(ctx, player,
                jewellery_capabilities.DEXTERITY))),
    }
end

function attributes.run(ctx)
    return attributes.current(ctx, ctx:player())
end

register.policy({
    id = "character.attributes",
    run = attributes.run,
})

return attributes
