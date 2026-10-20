-- The sunken Temple has variable altars and an open-sea border. Its two
-- hooks stay on opposite sides of the intervening static DES operations.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local fill = require("constants.vault_border_fill")

local handler = {}

-- Substitute the saved number of ordinary altars before transforming
-- the remaining O cells into the source's ecumenical/floor mix.
local function place_altars(api)
    api:emit(directives.NSUBST,
        "O = " .. count.selected(api) .. ":B / 1:O.... / *:.")
end

-- Retain the sea surrounding this map as typed generation data. The
-- Temple installer can apply it without special-casing this map ID.
local function fill_border(api)
    api:record(effects.BORDER_FILL, {
        style = fill.OPEN_SEA,
    })
end

handler.place_altars = place_altars
handler.fill_border = fill_border

return handler
