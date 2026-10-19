-- Example: Before absolute depth 16, the earth shop uses its weaker marker-1 population.
local directives = require("constants.vault_directives")

local handler = {}

-- Before absolute depth 16, the earth shop uses its weaker marker-1 population.
local function choose_earth_population(api)
    if api:absolute_depth() < 16 then
        api:emit(directives.SUBST, "2 = 1")
    end
end

handler.choose_earth_population = choose_earth_population

return handler
