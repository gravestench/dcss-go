-- Theory of operation: the source Vestibule paints five themed wings from
-- tagged child vaults. The only random script site changes its ':' corridors
-- after the wing substitutions are set up. Retaining that site in the DES
-- order keeps the rare Murray encounter tied to the same source draw.
local directives = require("constants.vault_directives")

local handler = {}

-- The first coin flip seals the spare corridors as rock. Otherwise the
-- second flip either opens them or reserves one Murray spawn and opens the
-- rest. The second draw must not happen when the first result is rock.
local function murray_corridor(api)
    if not api:coinflip() then
        api:emit(directives.SUBST, ": = x")

        return
    end

    if not api:coinflip() then
        api:emit(directives.SUBST, ": = .")

        return
    end

    api:emit(directives.MONS, "Murray")
    api:emit(directives.NSUBST, ": = 1:1 / *:.")
end

handler.murray_corridor = murray_corridor

return handler
