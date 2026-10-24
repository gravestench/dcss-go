-- Monster Confusion brand shares the player's saved confusion timer with
-- spells and clouds. A successful hit extends rather than replaces it.
local confusion = require("policy.magic.player_confusion")
local roll = require("policy.combat.roll")

local brand = {}

-- Chaos may select Confusion even when the ordinary weapon never carried
-- that brand. The player status owner handles later movement redirection.
function brand.apply(ctx, hit)
    local turns = 2 + roll.melee(ctx, 3)

    confusion.extend(ctx, hit.defender, turns)
    ctx:emit("combat", "You feel confused.")
end

return brand
