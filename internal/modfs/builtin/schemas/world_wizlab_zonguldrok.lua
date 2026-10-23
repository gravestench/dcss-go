-- Zonguldrok's source markers form one encounter. The surviving grave
-- bitset, wave counters, door, and lich flag belong to one saved Akara
-- owner; marker coordinates and indices witness the immutable DES map.
local component = require("constants.component")

register.component({
    id = component.WORLD_WIZLAB_ZONGULDROK,
    version = 1,
    fields = {
        level_id = {
            type = "int64",
            default = 0,
        },
        vault_id = {
            type = "string",
            default = "",
        },
        clock_index = {
            type = "int64",
            default = 0,
        },
        door_index = {
            type = "int64",
            default = 0,
        },
        door_x = {
            type = "int64",
            default = 0,
        },
        door_y = {
            type = "int64",
            default = 0,
        },
        next_aut = {
            type = "int64",
            default = 0,
        },
        count = {
            type = "int64",
            default = 0,
        },
        vampire_count = {
            type = "int64",
            default = 0,
        },
        warrior_count = {
            type = "int64",
            default = 0,
        },
        champion_count = {
            type = "int64",
            default = 0,
        },
        killed = {
            type = "int64",
            default = 0,
        },
        door_appeared = {
            type = "bool",
            default = false,
        },
        awoke = {
            type = "bool",
            default = false,
        },
        grave_indices = {
            type = "list<int64>",
        },
        grave_x = {
            type = "list<int64>",
        },
        grave_y = {
            type = "list<int64>",
        },
        grave_active = {
            type = "list<bool>",
        },
        wizard_x = {
            type = "int64",
            default = 0,
        },
        wizard_y = {
            type = "int64",
            default = 0,
        },
        wizard_index = {
            type = "int64",
            default = 0,
        },
        awaken_x = {
            type = "list<int64>",
        },
        awaken_y = {
            type = "list<int64>",
        },
    },
})
