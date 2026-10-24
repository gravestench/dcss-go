-- Theory of operation: an unearthed body ages while its floor is active.
-- Expiry writes zero HP before actor.death, so the real death owner can
-- produce its corpse and run any future Necromancy death hooks.
local component = require("constants.component")
local wretches = require("policy.religion.kikubaaqudgha.wretches")

local system = {}

-- Only marked monsters use this short clock; ordinary actors keep their
-- separate enchantment and regeneration owners.
function system.update(ctx, entity, elapsed_aut)
    if ctx:has(entity, component.RELIGION_KIKU_WRETCH) then
        wretches.tick(ctx, entity, elapsed_aut)
    end
end

register.system({
    id = "religion.kiku_wretch",
    scope = "active",
    query = {},
    after = { "monster.enchant" },
    before = { "monster.decision", "actor.death" },
    update = system.update,
})

return system
