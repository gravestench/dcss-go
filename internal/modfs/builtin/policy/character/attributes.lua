-- Example: A Strength mutation and a ring bonus both enter current Strength before its cap.
local capabilities = require("constants.mutation_capabilities")
local mutation_effects = require("policy.mutations.effects.registry")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local jewellery_capabilities = require("constants.jewellery_capabilities")
local artefact_ids = require("ids.artefact_properties")

local attributes = {}

local maximum = 125

-- Attribute consumers share this cap and additive ordering for base, mutation, jewellery, and artefact bonuses.
function attributes.current(ctx, player)
    local base = ctx:get(player, "core.attributes")

    if not base then
        error("player lacks base attributes")
    end

    local artefacts = require("policy.item_generation.artefacts.properties")

    return {
        strength = math.max(0, math.min(maximum, base.strength -
            stat_loss.amount(ctx, player, stats.STRENGTH) +
            mutation_effects.base_sum(ctx, player,
                capabilities.STRENGTH) +
            jewellery_effects.sum(ctx, player,
                jewellery_capabilities.STRENGTH) +
            artefacts.sum_worn(ctx, player,
                artefact_ids.STRENGTH))),
        intelligence = math.max(0, math.min(maximum, base.intelligence -
            stat_loss.amount(ctx, player, stats.INTELLIGENCE) +
            mutation_effects.base_sum(ctx, player,
                capabilities.INTELLIGENCE) +
            jewellery_effects.sum(ctx, player,
                jewellery_capabilities.INTELLIGENCE) +
            artefacts.sum_worn(ctx, player,
                artefact_ids.INTELLIGENCE))),
        dexterity = math.max(0, math.min(maximum, base.dexterity -
            stat_loss.amount(ctx, player, stats.DEXTERITY) +
            mutation_effects.base_sum(ctx, player,
                capabilities.DEXTERITY) +
            jewellery_effects.sum(ctx, player,
                jewellery_capabilities.DEXTERITY) +
            artefacts.sum_worn(ctx, player,
                artefact_ids.DEXTERITY))),
    }
end

-- Expose the same derived stat query to the policy command for the current player.
function attributes.run(ctx)
    return attributes.current(ctx, ctx:player())
end

register.policy({
    id = "character.attributes",
    run = attributes.run,
})

return attributes
