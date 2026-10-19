-- Theory of operation: the marked actor owns the timer, so each of its
-- actions ages the condition before it chooses another melee or spell.
local component = require("constants.component")
local mark = require("policy.combat.monster_black_mark")

local system = {}

-- A saved Black Mark expires independently of its original caster.
function system.update(ctx, monster, elapsed_aut)
    mark.tick(ctx, monster, elapsed_aut)
end

register.system({
    id = "combat.monster_black_mark.tick",
    scope = "active",
    query = { component.MONSTER_BLACK_MARK },
    before = { "monster.decision" },
    update = system.update,
})

return system
