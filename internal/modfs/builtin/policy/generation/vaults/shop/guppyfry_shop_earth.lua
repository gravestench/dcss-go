local directives = require("constants.vault_directives")

local handler = {}

-- Port of builder/shops.des:549-551.
local function choose_earth_population(api)
    if api:absolute_depth() < 16 then
        api:emit(directives.SUBST, "2 = 1")
    end
end

handler.choose_earth_population = choose_earth_population

return handler
