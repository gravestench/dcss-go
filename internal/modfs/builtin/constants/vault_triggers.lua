-- A placed DES marker names a Lua gameplay callback in a mod layer.
-- The prefix separates active triggers from unrelated source markers.
local triggers = {
    PREFIX = "vault_trigger:",
    SPIDER_NEST_SPAWN = "vault_trigger:spider_nest.spawn",
    SPIDER_NEST_WARN = "vault_trigger:spider_nest.warn",
}

return triggers
