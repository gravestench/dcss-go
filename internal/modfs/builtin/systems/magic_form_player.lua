local forms = require("policy.magic.effects.forms.player")
local system = {}

function system.update(ctx, actor, aut)
    if actor == ctx:player() then
        forms.tick(ctx, actor, aut)
    end
end

register.system({
    id = "magic.player_form.tick",
    scope = "active",
    query = {},
    after = { "status.duration" },
    before = { "magic.player_status.tick" },
    update = system.update,
})

return system
