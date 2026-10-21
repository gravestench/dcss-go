-- The honeycomb stair room applies the same local-depth source condition.
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the stair draw before the subsequent zero and nine substitutions.
local function stair_substitution(api)
    if api:depth() == 1 then
        api:emit(directives.SUBST, "{ = }")
    elseif api:depth_fraction() < 1 then
        api:emit(directives.SUBST, "{ = {}")
    end
end

handler.stair_substitution = stair_substitution

return handler
