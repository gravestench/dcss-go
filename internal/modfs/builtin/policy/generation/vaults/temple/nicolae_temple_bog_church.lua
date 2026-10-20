-- The bog church can host every ordinary Temple count. Its B cells are
-- chosen from the saved count; the other B cells become scenery or floor.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the source's two single-cell special outcomes after the selected
-- altars, before the remaining B cells turn into ordinary floor.
local function configure(api)
    api:emit(directives.NSUBST,
        "B = " .. count.selected(api) .. "=B / 1:{ / 1:` / -")
end

handler.configure = configure

return handler
