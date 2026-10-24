-- Each monster owns a small, saved set of legal same-power destinations.
-- Source `init_poly_set` rolls this on creation and after each body change;
-- keeping it on the entity makes later spell casts and saved games agree.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_POLYMORPH_SET,
    version = 1,
    fields = {
        forms = {
            type = "list<string>",
            default = {},
        },
    },
}

register.component(schema)

return schema
