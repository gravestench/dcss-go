local tactical = require("constants.monster_tactical")
local venom = require("policy.combat.monster_tactical.concentrate_venom")

local system = {}

-- Theory of operation: only the active recipient ages the saved enchant,
-- so off-turn allies keep their source duration until their own action.
function system.update(ctx, recipient, elapsed_aut)
    venom.tick(ctx, recipient, elapsed_aut)
end

register.system({
    id = "magic.concentrate_venom.tick",
    scope = "active",
    query = { tactical.CONCENTRATE_VENOM },
    before = { "monster.decision" },
    update = system.update,
})

return system
