local component = require("constants.component")

register.component({
    id = component.SHOPPING_LIST,
    version = 1,
    fields = {
        stock_ids = { type = "list<entity>" },
    },
})
