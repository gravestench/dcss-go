-- One Akara entity owns each realized Treasure Trove entrance. The grid
-- keeps its source marker as an immutable price witness; this component
-- owns the gate's state and the item or piety receipt after payment.
local component = require("constants.component")

register.component({
    id = component.WORLD_TROVE_PORTAL,
    version = 1,
    fields = {
        level_id = {
            type = "int64",
            default = 0,
        },
        x = {
            type = "int64",
            default = 0,
        },
        y = {
            type = "int64",
            default = 0,
        },
        vault_id = {
            type = "string",
            default = "",
        },
        record_index = {
            type = "int64",
            default = 0,
        },
        price_kind = {
            type = "string",
            default = "",
        },
        item_id = {
            type = "string",
            default = "",
        },
        quantity = {
            type = "int64",
            default = 0,
        },
        minimum_plus = {
            type = "int64",
            default = 0,
        },
        ego_id = {
            type = "string",
            default = "",
        },
        artefact_name = {
            type = "string",
            default = "",
        },
        source_rune_index = {
            type = "int64",
            default = 0,
        },
        price_witness = {
            type = "string",
            default = "",
        },
        spent = {
            type = "bool",
            default = false,
        },
        closure_reason = {
            type = "string",
            default = "",
        },
        receipt_kind = {
            type = "string",
            default = "",
        },
        receipt_item_id = {
            type = "string",
            default = "",
        },
        receipt_quantity = {
            type = "int64",
            default = 0,
        },
        destination_id = {
            type = "string",
            default = "",
        },
    },
})
