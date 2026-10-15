local component = require("constants.component")
local clutch = require("policy.magic.effects.statuses.vile_clutch")
local system = {}

function system.decay(ctx, actor)
    if ctx:has(actor, component.AI) then
        clutch.tick_monster(ctx, actor)
    end
end

function system.damage(ctx, actor, aut)
    if actor == ctx:player() then
        clutch.damage_player_action(ctx, actor, aut)
    end
end

register.system({
    id = "magic.monster_vile_clutch.decay",
    scope = "active",
    query = {},
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.decay,
})

register.system({
    id = "magic.monster_vile_clutch.damage",
    scope = "active",
    query = {},
    after = { "attack.combat" },
    before = { "actor.death" },
    update = system.damage,
})

return system
