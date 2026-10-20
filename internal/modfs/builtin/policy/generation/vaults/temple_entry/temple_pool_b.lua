-- The pool entrance has two source layouts for its water channels. The
-- authored MAP remains in DES; this hook chooses its SHUFFLE and SUBST
-- directives at the same position as the source conditional.
local directives = require("constants.vault_directives")

local handler = {}

-- The rare three-in-ten variant opens one bank. Otherwise four shuffled
-- channel groups remain, with the source's second local shuffle intact.
local function choose_pool_pattern(api)
    if api:roll(10) < 3 then
        api:emit(directives.SHUFFLE, "XY")
        api:emit(directives.SUBST, "X = ., ABCDEFGHIJKLMNPQY = w")

        return
    end

    api:emit(directives.SHUFFLE, "ABCD / EFGH / IJKL / MNPQ")
    api:emit(directives.SHUFFLE, "AB, EF, IJ, MN")
    api:emit(directives.SUBST,
        "ACD = W, B = wW, EFGHIJKLMNPQXY = w")
end

handler.choose_pool_pattern = choose_pool_pattern

return handler
