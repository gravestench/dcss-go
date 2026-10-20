-- Theory of operation: this Dithmenos map places a shadow after absolute
-- depth eight. Earlier floors mix phantoms and shadow imps; the local depth
-- determines the two weights so the darker choice grows more common.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit one MONS slot at the source block position, before the extra-vault
-- interest hook, so a later placement never sees two populations.
local function choose_shadows(api)
    if api:absolute_depth() >= 9 then
        api:emit(directives.MONS, "shadow")

        return
    end

    local imp_weight = 9 - api:depth()

    if imp_weight <= 0 then
        api:emit(directives.MONS, "shadow imp")

        return
    end

    local phantom_weight = 9 - imp_weight

    api:emit(directives.MONS,
        "phantom w:" .. phantom_weight ..
        " / shadow imp w:" .. imp_weight)
end

handler.choose_shadows = choose_shadows

return handler
