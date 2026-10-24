-- Theory of operation: a player action advances the saved Beogh recall
-- queue after movement and stair travel have selected the active floor.
local component = require("constants.component")
local recall = require("policy.abilities.beogh.recall")

local system = {}

-- Monster actions do not spend the player's recall timer. The ability's
-- opening action does, exactly as a normal movement or wait action does.
function system.update(ctx, actor, elapsed_aut)
    if actor == ctx:player() and
        ctx:has(actor, component.BEOGH_RECALL) then
        recall.tick(ctx, actor, elapsed_aut)
    end
end

register.system({
    id = "religion.beogh_recall",
    scope = "active",
    query = { component.PLAYER },
    after = { "world.stairs" },
    before = { "actor.death" },
    update = system.update,
})

return system
