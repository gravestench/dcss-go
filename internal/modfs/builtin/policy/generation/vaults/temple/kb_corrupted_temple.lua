-- The rare corrupted Temple keeps Lugonu's authored feature and its
-- demonic plants. Its ordinary altars and rock colour are separate choices.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

local rock_colours = {
    "magenta", "lightblue", "lightcyan", "lightred",
}

-- Fill the O pool from the saved count, then roll one of the four source
-- rock colours. The colour draw never changes which altars were selected.
local function configure(api)
    api:emit(directives.NSUBST,
        "O = " .. count.selected(api) .. ":B / 6:L / * = LP")

    local colour = rock_colours[api:roll(#rock_colours) + 1]

    api:emit(directives.LROCKCOL, colour)
end

handler.configure = configure

return handler
