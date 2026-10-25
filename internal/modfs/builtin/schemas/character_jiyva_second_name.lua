-- Crawl generates Jiyva's second name for every new character, whether
-- or not they later worship Jiyva. It must survive save/restore unchanged.
local component = require("constants.component")

local schema = {
    id = component.JIYVA_SECOND_NAME,
    version = 1,
    fields = {
        name = {
            type = "string",
            default = "",
        },
    },
}

register.component(schema)

return schema
