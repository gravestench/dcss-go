local categories = require("constants.catalog")
local source = require("content.monsters.0466_mons_plant")

-- A mod can add a spawnable catalog record without copying the source profile.
local definition = {}

for key, value in pairs(source) do
    definition[key] = value
end

definition.id = "MONS_VAULT_SPROUT"
definition.name = "vault sprout"
definition.genus_id = definition.id
definition.species_id = definition.id

register.definition(categories.MONSTERS, definition)

return definition
