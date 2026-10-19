local component = require("constants.component")

register.component({
    id = component.SHOP_STOCK,
    version = 1,
    -- Shop ID and stock order keep an item in its original display position after level reload.
    fields = {
        shop_id = { type = "uint64", default = 0 },
        order = { type = "int64", default = 0 },
    },
})
