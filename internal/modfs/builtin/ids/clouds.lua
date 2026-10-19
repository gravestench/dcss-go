-- Cloud IDs resolve cloud definitions for placement and damage rules.

local catalog = require("ids.catalog")
local categories = require("constants.catalog")

return catalog.registered(categories.CLOUDS)
