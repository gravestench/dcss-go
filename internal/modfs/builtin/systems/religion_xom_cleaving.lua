-- Cleaving is spent after an attack has consulted its current duration.
local cleaving = require("policy.religion.xom.cleaving")
local component = require("constants.component")

local system = {}

-- Monster and zero-cost actions never consume a player's Xom duration.
function system.update(ctx, actor, elapsed_aut)
    if actor == ctx:player() then
        cleaving.tick(ctx, actor, elapsed_aut)
    end
end

register.system({
    id = "religion.xom_cleaving",
    scope = "active",
    query = { component.PLAYER },
    after = { "attack.combat" },
    before = { "religion.xom.reaction" },
    update = system.update,
})

return system
