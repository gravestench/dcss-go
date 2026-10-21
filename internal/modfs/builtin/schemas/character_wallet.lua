local component = require("constants.component")

register.component({
    id = component.WALLET,
    version = 1,
    -- Gold balance and purchase history remain on the character after shops or levels unload.
    fields = {
        gold = { type = "int64", default = 0 },
        purchases = { type = "int64", default = 0 },

        -- DCSS prices Gozag's entry from gold generated on explored floors,
        -- regardless of what the player has actually collected or spent.
        generated_gold = {
            type = "int64",
            default = 0,
        },
    },
})
