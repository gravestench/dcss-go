-- The pigsty's source marker properties link one authored monster death
-- to one authored gate without storing a Lua closure inside a save.
local pigsty = {
    MAP_ID = "pan_captured_pigsty",
    SWINEHERD_PROPERTY = "monster_dies_lua_key",
    SWINEHERD_VALUE = "swineherd_die",
    GATE_PROPERTY = "pigsty_gate",
    GATE_VALUE = "1",
    MISSING_GATE = "Error: someone stolen the pigsty gate!",
    VISIBLE_OPEN = "The grate goes up!",
    HEARD_OPEN = "You hear a sound of rusty metal sliding.",
}

return pigsty
