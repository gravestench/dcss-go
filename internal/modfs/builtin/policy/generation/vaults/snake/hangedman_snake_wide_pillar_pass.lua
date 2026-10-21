-- Theory of operation: the wider pillar pass uses the same source depth
-- probability as its thin sibling but keeps its own authored SHUFFLE and
-- stone pattern in the DES file. Early Snake floors have more closed rock.
local directives = require("constants.vault_directives")

local handler = {}

-- Use branch-local depth rather than the absolute Dungeon depth: the
-- source fraction counts how many Snake floors remain below this map.
function handler.configure(api)
    local bottom = api:branch_bottom()
    local remaining = bottom - api:depth()

    if api:chance(remaining, bottom) then
        api:emit(directives.SUBST, "c = x")
    end
end

return handler
