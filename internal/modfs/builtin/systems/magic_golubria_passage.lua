local golubria = require("policy.magic.effects.translocation.golubria")

local system = {}

-- Theory of operation: The passage relocates a mover before combat resolves against that destination.
-- Passage triggers after movement reaches a cell and before combat uses the new position.
function system.update(ctx, actor)
    golubria.trigger(ctx, actor)
end

register.system({
    id = "magic.golubria_passage.trigger",
    scope = "active",
    query = {},
    after = { "world.movement" },
    before = { "attack.combat" },
    update = system.update,
})

return system
