-- Branch IDs identify destinations in travel and population rules.

local catalog = require("ids.catalog")
local categories = require("constants.catalog")

return catalog.registered(categories.BRANCHES)
