-- The familiar Temple keeps only the selected number of B altars. One
-- unmatched cell may become a closed shop; the rest become plain floor.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Emit the source NSUBST before the authored door substitutions that
-- follow this hook in DES.
local function configure(api)
    api:emit(directives.NSUBST,
        "B = " .. count.selected(api) .. ":B / 1:Q. / *:.")
end

handler.configure = configure

return handler
