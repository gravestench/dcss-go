local component = require("constants.component")

register.component({
    id = component.SHOP,
    version = 1,
    -- Shop kind, location, greed, and keeper seed remain stable when a level unloads and reloads.
    fields = {
        kind_id = { type = "string", default = "" },
        level_id = { type = "int64", default = 0 },
        x = { type = "int64", default = 0 },
        y = { type = "int64", default = 0 },
        name = { type = "string", default = "" },
        greed = { type = "int64", default = 10 },
        open = { type = "bool", default = true },
        keeper_seed = { type = "uint64", default = 0 },
    },
})
