local training = require("policy.character.training")

local system = {}

-- Theory of operation: An active monster can die, credit player XP, or
-- strike the player for defensive practice. Run after that actor's death
-- phase so every earned award reaches the player's skill ledger before
-- level advancement, even if the player is not the acting entity.
function system.update(ctx)
    local player = ctx:player()

    if player then
        training.update(ctx, player)
    end
end

register.system({
    id = "character.training",
    scope = "active",
    query = {},
    after = { "actor.death" },
    before = { "character.advancement" },
    update = system.update,
})

return system
