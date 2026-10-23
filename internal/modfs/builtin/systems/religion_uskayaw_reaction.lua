-- Player reactions turn the current action's pooled damage into Uskayaw
-- piety after combat and death effects, then advance quiet-turn decay.
local uskayaw = require("policy.religion.conduct.uskayaw")

local system = {}

-- Only the player action advances this clock; monster actions must not
-- empty the pool between two hits in one committed player turn.
function system.update(ctx, actor, elapsed_aut)
    if actor == ctx:player() then
        uskayaw.tick(ctx, actor, elapsed_aut)
    end
end

register.system({
    id = "religion.uskayaw.reaction",
    scope = "active",
    query = {},
    after = { "actor.death" },
    update = system.update,
})

return system
