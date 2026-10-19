-- Theory of operation: this active phase removes expired soul marks before
-- monster decisions and later death processing can turn bodies into undead.
-- The timer is an absolute aut deadline, so it needs no per-turn mutation.
local component = require("constants.component")
local bound_souls = require("policy.combat.monster_bound_souls")

local system = {}

-- Expiry clears the saved mark. The death hook performs conversion only
-- while its deadline remains in the future.
function system.update(ctx, actor)
    local mark = ctx:get(actor, component.MONSTER_BOUND_SOUL)

    if mark and mark.expires_aut <= ctx:aut() then
        ctx:remove(actor, component.MONSTER_BOUND_SOUL)
    end
end

register.system({
    id = "magic.monster_bound_soul.tick",
    scope = "active",
    query = { component.MONSTER_BOUND_SOUL },
    before = { "monster.decision" },
    update = system.update,
})

return system
