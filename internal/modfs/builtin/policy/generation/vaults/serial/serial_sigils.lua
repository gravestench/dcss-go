-- Theory of operation: the rare Depths, Elf, or Crypt controller owns no
-- terrain. After its source CHANCE succeeds, it asks the weighted selector
-- for four through six sigil shapes. Each shape retains its own geometry,
-- source weight, and floor/wall decoration in its DES definition.
local tags = require("constants.vault_tags")
local handler = {}

-- One bounded draw keeps the source's flat four-to-six group-size choice.
local function place_sigils(api)
    local count = 4 + api:roll(3)

    api:place_maps(tags.SERIAL_SIGILS, count)
end

handler.place_sigils = place_sigils

return handler
