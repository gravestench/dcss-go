-- The carousel either welcomes a descent into its center or makes the
-- player cross the spectators before reaching the stairs. Its DES owns
-- all geometry and the shared glass hook owns its colour assignments.
local directives = require("constants.vault_directives")

local handler = {}

-- One coinflip selects a coherent stair and guardian substitution set.
-- The later source glass hook runs after these substitutions in DES order.
local function choose_entry_side(api)
    if api:coinflip() then
        api:emit(directives.NSUBST,
            "> = 1 = }:80 > / 1 = ):80 > / 1 = ]:80 >")
        api:emit(directives.SUBST, "1 = 1 0:30 .")

        return
    end

    api:emit(directives.NSUBST, "G = 3={[( / *:G")
    api:emit(directives.NSUBST, "1 = 6 = 1. / *=0...")
    api:emit(directives.NSUBST, "> = >. / *:.")
end

handler.choose_entry_side = choose_entry_side

return handler
