-- Theory of operation: deeper Shoals floors progressively harden the
-- volcanic island. Two independent source draws choose the siren/avatar
-- guard and the fire-crab substitution before the fixed DES decorations.
local directives = require("constants.vault_directives")

local handler = {}

-- Give the avatar a depth-scaled chance, then shuffle the matching guard set.
local function choose_guards(api)
    if api:roll(api:depth() + 4) <= api:depth() then
        api:emit(directives.SUBST, "3 = 4")
        api:emit(directives.SHUFFLE, '12 / 4"')
    else
        api:emit(directives.SHUFFLE, '12 / 3"')
    end
end

-- The second source draw independently upgrades a bat position to a crab.
local function choose_crab(api)
    if api:roll(api:depth() + 4) <= api:depth() then
        api:emit(directives.SUBST, "7 = 8")
    end
end

handler.choose_guards = choose_guards
handler.choose_crab = choose_crab

return handler
