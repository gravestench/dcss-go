local component = require("constants.component")

register.component({
    id = component.SHOPPING_LIST,
    version = 1,
    -- Saved stock IDs keep a marked shop item recognizable even if the player leaves the level.
    fields = {
        stock_ids = { type = "list<entity>" },
    },
})
