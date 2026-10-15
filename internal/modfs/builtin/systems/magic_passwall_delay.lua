local passwall = require("policy.magic.effects.translocation.passwall")

local system = {}

function system.update(ctx, actor, aut)
    if actor == ctx:player() then
        passwall.tick(ctx, actor, aut)
    end
end

register.system({
    id = "magic.passwall_delay.tick",
    scope = "active",
    query = {},
    after = { "attack.player_spell" },
    before = { "world.movement" },
    update = system.update,
})

return system
