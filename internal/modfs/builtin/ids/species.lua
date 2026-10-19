-- Species IDs select character creation traits and aptitude tables.

local catalog = require("ids.catalog")
local categories = require("constants.catalog")

return catalog.registered(categories.SPECIES)
