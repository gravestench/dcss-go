-- Vault IDs identify authored DES maps across selection and saved origin records.

local categories = require("constants.catalog")
local catalog_ids = require("ids.catalog")

return catalog_ids.registered(categories.VAULTS)
