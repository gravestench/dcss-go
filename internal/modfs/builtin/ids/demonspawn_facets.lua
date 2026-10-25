-- Resolve facet IDs after layered content has registered its definitions.
-- Policies can refer to a facet without repeating its declaration string.
local catalog = require("ids.catalog")
local categories = require("constants.catalog")

return catalog.registered(categories.DEMONSPAWN_FACETS)
