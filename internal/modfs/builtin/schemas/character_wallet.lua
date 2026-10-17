local component = require("constants.component")

register.component({
    id = component.WALLET,
    version = 1,
    fields = {
        gold = { type = "int64", default = 0 },
        purchases = { type = "int64", default = 0 },
    },
})
