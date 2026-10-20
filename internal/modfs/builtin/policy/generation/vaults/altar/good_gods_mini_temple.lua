-- Theory of operation: the small three-god temple varies the outer garden
-- without changing its altar identities. One coin flip either shuffles four
-- paired glyph groups or opens quoted cells before shared substitutions.
local directives = require("constants.vault_directives")

local handler = {}

-- Consume one source coin flip, then leave common map directives to the DES.
local function vary_garden(api)
    if api:coinflip() then
        api:emit(directives.SHUFFLE, "x\" / t1 / wT / IJ")
    else
        api:emit(directives.SUBST, "\" : ..x")
    end
end

handler.vary_garden = vary_garden

return handler
