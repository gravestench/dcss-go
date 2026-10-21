-- A placed DES marker names a Lua gameplay callback in a mod layer.
-- The prefix separates active triggers from unrelated source markers.
local triggers = {
    PREFIX = "vault_trigger:",
    SPIDER_NEST_SPAWN = "vault_trigger:spider_nest.spawn",
    SPIDER_NEST_WARN = "vault_trigger:spider_nest.warn",
    LADY_OF_LAKE_SPAWN = "vault_trigger:lady_of_lake.spawn",
    MERFOLK_AVATAR_TARGET = "vault_target:merfolk_avatar",
}

return triggers
