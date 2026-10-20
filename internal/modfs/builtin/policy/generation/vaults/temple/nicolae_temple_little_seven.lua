-- The little seven Temple alternates which lettered cells are altars,
-- paths, and scenery. One source coin flip chooses the complete pattern.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit one whole substitution, so both source layouts remain reachable
-- without letting the later static shuffle change the number of altars.
local function configure(api)
    if api:roll(2) == 0 then
        api:emit(directives.SUBST, "DJ = G, EH = ., F = B, KLM = x")

        return
    end

    api:emit(directives.SUBST, "DEF = x, HM = G, JL = ., K = B")
end

handler.configure = configure

return handler
