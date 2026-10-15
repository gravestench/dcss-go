local catalog = require("ids.catalog")
local categories = require("constants.catalog")

local mutations = catalog.registered(categories.MUTATIONS)

return mutations
