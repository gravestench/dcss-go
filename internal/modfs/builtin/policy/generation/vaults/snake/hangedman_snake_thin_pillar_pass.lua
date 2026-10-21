-- Theory of operation: source Snake pillars can harden as the player moves
-- deeper into the branch. The chance is remaining floors divided by total
-- floors, so early maps tend to replace the decorative c cells with rock.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit the substitution at the original script site, after the source
-- SHUFFLE and first SUBST but before the MAP is projected onto the floor.
function handler.configure(api)
    local bottom = api:branch_bottom()
    local remaining = bottom - api:depth()

    if api:chance(remaining, bottom) then
        api:emit(directives.SUBST, "c = x")
    end
end

return handler
