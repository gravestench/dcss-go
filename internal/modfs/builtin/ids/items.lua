local catalog = require("ids.catalog")
local categories = require("constants.catalog")

local items = catalog.registered(categories.ITEMS)

-- A melee equipment state rather than an inventory catalog record.
items.WPN_UNARMED = "WPN_UNARMED"

return items
