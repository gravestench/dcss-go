local component = require("constants.component")
local shapeshifter = require("policy.monsters.shapeshifter")

local system = {}

-- Theory of operation: the active actor's permanent shape state gets one
-- source enchantment chance before it selects its next AI action. The owner
-- policy suppresses changes while the body is unable to act.
function system.update(ctx, monster)
    if ctx:has(monster, component.AI) then
        shapeshifter.tick(ctx, monster)
    end
end

register.system({
    id = "monster.shapeshift",
    scope = "active",
    query = { component.MONSTER_SHAPESHIFTER },
    before = { "monster.decision" },
    update = system.update,
})

return system
