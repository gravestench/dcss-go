-- The third sculpture varies its central columns before the shared
-- substitutions turn unused decoration glyphs into masonry and glass.
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the source coin flip ahead of either branch's SHUFFLE draws.
local function configure(api)
    if api:one_in(2) then
        api:emit(directives.SHUFFLE, "bcegh")
        api:emit(directives.SUBST, "b = .")
        api:emit(directives.SHUFFLE, "acdefghi")
    else
        api:emit(directives.SUBST, "f = v")
        api:emit(directives.SHUFFLE, "abcdeghi")
    end
end

handler.configure = configure

return handler
