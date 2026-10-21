-- Theory of operation: the second standard ending shuffles dragon slots
-- before a one-in-eleven source script turns its surviving O or P guardian
-- into the Lernaean hydra. Both forms already carry the rune KITEM rule.
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the guardian and nearby wall variation in one conditional source step.
local function rare_lernaean_hydra(api)
    if api:one_in(11) then
        api:emit(directives.SUBST, "6 = .:999 6:1, OP = &")
    end
end

handler.rare_lernaean_hydra = rare_lernaean_hydra

return handler
