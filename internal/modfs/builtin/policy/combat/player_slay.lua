local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local statuses = require("policy.magic.effects.statuses.player")
local horror = require("policy.character.horror")

local player_slay = {}

-- Source: player.cc:slaying_bonus includes Wereblood and three points for
-- each active Augmentation tier in both melee and ranged attacks.
function player_slay.total(ctx, player)
    local augmentation = effects.sum(ctx, player,
        capabilities.AUGMENTATION)

    return statuses.wereblood_slay(ctx, player) + 3 * augmentation -
        horror.penalty(ctx, player)
end

return player_slay
