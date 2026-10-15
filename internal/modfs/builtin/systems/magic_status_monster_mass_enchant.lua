local component = require("constants.component")
local mass = require("policy.magic.effects.statuses.mass_enchantment")
local system = {}

function system.update(ctx, entity)
    if ctx:has(entity, component.AI) then
        mass.tick(ctx, entity)
    end
end

register.system({
    id = "magic.monster_mass_enchant.tick",
    scope = "active",
    query = {},
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.update,
})

return system
