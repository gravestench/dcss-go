-- Trap IDs identify placed trap kinds and their activation policy.

local catalog = require("ids.catalog")
local categories = require("constants.catalog")

return catalog.registered(categories.TRAPS)
