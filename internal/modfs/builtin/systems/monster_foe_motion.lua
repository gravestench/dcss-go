-- Theory of operation: immediately before a monster decision, record
-- whether its current foe advanced since this monster last acted. Wall of
-- Brambles reads that saved fact to choose defensive or distant geometry.
local component = require("constants.component")
local motion = require("policy.ai.foe_motion")

local system = {}

-- Only active AI actors make an observation; other actors have no foe.
function system.update(ctx, monster)
    if ctx:has(monster, component.AI) then
        motion.observe(ctx, monster)
    end
end

register.system({
    id = "monster.foe_motion",
    scope = "active",
    query = { component.AI },
    before = { "monster.decision" },
    update = system.update,
})

return system
