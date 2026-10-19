-- Unique artefact IDs resolve through the effective artefact catalog.

local catalog = require("ids.catalog")
local categories = require("constants.catalog")

return catalog.registered(categories.ARTEFACTS)
