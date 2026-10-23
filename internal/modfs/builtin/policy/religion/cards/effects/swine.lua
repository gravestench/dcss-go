-- Swine forces the player's existing Pig Form and uses the card's own
-- duration formula. The form owner handles equipment, HP, and expiry.
local forms = require("policy.magic.effects.forms.player")
local streams = require("constants.rng_streams")

local swine = {}

-- Source rolls one variable duration after its fixed power contribution.
-- Refused transformations still consume that roll and print the oink text.
function swine.apply(ctx, player, request)
    local tenth = math.floor(request.power / 10)
    local variance = tenth > 0 and
        ctx:random(streams.CARDS, tenth) or 0
    local turns = 5 + tenth + variance

    if not forms.porkalator(ctx, player, 0, turns * 10) then
        ctx:emit("religion", "You feel a momentary urge to oink.")
    end
end

return swine
