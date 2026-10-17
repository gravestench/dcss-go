local directives = require("constants.vault_directives")

local handler = {}

-- Port of builder/shops.des:522-524.
local function choose_venom_population(api)
    if api:absolute_depth() < 13 then
        api:emit(directives.SUBST, "2 = 1")
    end
end

handler.choose_venom_population = choose_venom_population

return handler
