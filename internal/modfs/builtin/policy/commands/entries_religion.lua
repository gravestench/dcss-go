-- Prayer is prepared with the saved altar record before the engine charges
-- time. The resolver handles conversion only after the accepted intent runs.
local commands = require("policy.input.commands")
local prayer = require("policy.religion.prayer")
local registry = require("policy.commands.registry")

local entries = {}

-- Bind the prayer command to the same preflight path as other player input.
function entries.pray(ctx, player, input, position)
    return prayer.prepare(ctx, player, input, position)
end

registry.register(commands.pray, entries.pray)

return entries
