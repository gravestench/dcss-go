-- Source paralyse_player rolls a duration based on the current saved
-- paralysis and then writes the player's one paralysis component. Gods
-- call this with no attacking actor, so immunity to repeated monster
-- paralysis does not block divine punishment.
local catalog = require("policy.catalog")
local component = require("constants.component")
local forms = require("policy.magic.effects.forms.player")
local species_traits = require("policy.character.species_traits")
local streams = require("constants.rng_streams")

local paralysis = {}

-- The source roll spans 2..5+current turns and then caps at 13. Stasis
-- rejects it before drawing, leaving the card stream unchanged.
function paralysis.divine(ctx, player, stream)
    local choice = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", choice.species_id)

    if species_traits.stasis(species) or forms.stasis(ctx, player) then
        ctx:emit("religion", "Your stasis prevents you from being paralysed.")

        return false
    end

    local current = ctx:get(player, component.PLAYER_PARALYSIS)
    local turns = current and
        math.floor(current.remaining_aut / 10) or 0
    local duration = math.min(13, 2 +
        ctx:random(stream or streams.CARDS, 4 + turns)) * 10
    local state = {
        remaining_aut = duration,
    }

    if current then
        ctx:set(player, component.PLAYER_PARALYSIS, state)
    else
        ctx:add(player, component.PLAYER_PARALYSIS, state)
    end

    ctx:emit("religion", "You suddenly lose the ability to move!")

    return true
end

return paralysis
