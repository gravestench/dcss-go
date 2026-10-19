-- Monster IDs link spawn records and actor components to monster definitions.

local catalog = require("ids.catalog")
local categories = require("constants.catalog")

return catalog.registered(categories.MONSTERS)
