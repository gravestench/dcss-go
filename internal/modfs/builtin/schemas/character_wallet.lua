local component = require("constants.component")

register.component({
    id = component.WALLET,
    version = 1,
    -- Gold balance and purchase history remain on the character after shops or levels unload.
    fields = {
        gold = { type = "int64", default = 0 },
        purchases = { type = "int64", default = 0 },
    },
})
