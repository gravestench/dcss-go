local forms = require("policy.magic.effects.forms.player")
local system = {}

-- Theory of operation: Expired form state is cleared before spell statuses use the current player shape.
-- Form duration is checked after general decay, before other player spell statuses.
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
