-- A placed DES marker names a Lua gameplay callback in a mod layer.
-- The prefix separates active triggers from unrelated source markers.
local triggers = {
    PREFIX = "vault_trigger:",
    ENTER_EVENT = "enter",
    MONSTER_DEATH_EVENT = "monster_death",
    DIS_MU_STATUE_AWAKEN = "vault_trigger:dis.mu_statue_awaken",
    SPIDER_NEST_SPAWN = "vault_trigger:spider_nest.spawn",
    SPIDER_NEST_WARN = "vault_trigger:spider_nest.warn",
    LADY_OF_LAKE_SPAWN = "vault_trigger:lady_of_lake.spawn",
    MERFOLK_AVATAR_TARGET = "vault_target:merfolk_avatar",
    ZOT_OVERGROWN_START = "zot_overgrown:start",
    ZOT_OVERGROWN_TICK = "zot_overgrown:tick",
    ZOT_OVERGROWN_TARGET = "lua:props_marker { oklobify=1 }",
    ZOT_OVERGROWN_CONTROLLER = "controller",
    ZOT_OVERGROWN_PLANT = "plant",
}

return triggers
