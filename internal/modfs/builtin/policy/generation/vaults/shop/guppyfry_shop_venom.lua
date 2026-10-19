-- Example: The venom shop downgrades marker 2 on floors shallower than absolute depth 13.
local directives = require("constants.vault_directives")

local handler = {}

-- The venom shop downgrades marker 2 on floors shallower than absolute depth 13.
local function choose_venom_population(api)
    if api:absolute_depth() < 13 then
        api:emit(directives.SUBST, "2 = 1")
    end
end

handler.choose_venom_population = choose_venom_population

return handler
