-- Tartarus stair glyphs change according to the local Hell depth.
local directives = require("constants.vault_directives")

local handler = {}

-- At depth one the source draws only a down stair; ordinary intermediate
-- depths permit either stair at this map position.
local function stair_substitution(api)
    if api:depth() == 1 then
        api:emit(directives.SUBST, "{ = }")
    elseif api:depth_fraction() < 1 then
        api:emit(directives.SUBST, "{ = {}")
    end
end

handler.stair_substitution = stair_substitution

return handler
