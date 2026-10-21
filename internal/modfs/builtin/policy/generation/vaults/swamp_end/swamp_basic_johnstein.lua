-- Theory of operation: source NSUBST leaves one O rune pocket. The rare
-- branch assigns the Lernaean hydra to that pocket; the ordinary branch
-- adds other swamp defenders and an unrelated prize at surviving * cells.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit one complete guardian branch so its monster and item rules agree.
local function choose_guardians(api)
    if api:one_in(11) then
        api:emit(directives.KMONS, "O = the lernaean hydra")
        return
    end

    api:emit(directives.KMONS,
        "O* = thorn hunter / shambling mangrove / spriggan berserker")
    api:emit(directives.KITEM, "* = *")
end

handler.choose_guardians = choose_guardians

return handler
