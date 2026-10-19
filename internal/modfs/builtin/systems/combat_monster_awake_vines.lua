-- Theory of operation: the caster's scheduled action ages its shared vine
-- enchant; each vine's own action checks its saved relation to the caster.
-- Both checks run before ordinary monster decisions and survive reloads.
local component = require("constants.component")
local vines = require("policy.combat.monster_plants.vines")

local system = {}

-- Only entities with plant state enter this system; no global vine scan
-- is needed on an ordinary monster turn.
function system.update(ctx, actor, aut)
    if ctx:has(actor, component.MONSTER_AWAKE_VINES) then
        vines.tick(ctx, actor, aut)
    end

    if ctx:has(actor, component.MONSTER_VINE) then
        vines.check_head(ctx, actor)
    end
end

register.system({
    id = "combat.monster_awake_vines",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = system.update,
})

return system
