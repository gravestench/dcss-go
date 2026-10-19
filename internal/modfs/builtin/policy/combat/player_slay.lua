local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local statuses = require("policy.magic.effects.statuses.player")
local horror = require("policy.character.horror")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local jewellery_capabilities = require("constants.jewellery_capabilities")
local artefacts = require("policy.item_generation.artefacts.properties")
local artefact_ids = require("ids.artefact_properties")

local player_slay = {}

-- Example: player_slay.total(ctx, player) with Augmentation level one -> three extra slaying before other modifiers
-- Source: player.cc:slaying_bonus includes Wereblood and three points for
-- each active Augmentation tier in both melee and ranged attacks.
function player_slay.total(ctx, player)
    local augmentation = effects.sum(ctx, player,
        capabilities.AUGMENTATION)

    return statuses.wereblood_slay(ctx, player) + 3 * augmentation -
        horror.penalty(ctx, player) +
        jewellery_effects.sum(ctx, player, jewellery_capabilities.SLAYING) +
        artefacts.sum_worn(ctx, player, artefact_ids.SLAYING)
end

return player_slay
