-- Theory of operation: one source draw in five inverts the hallway's rock
-- and floor before the later authored palette pass. The order matters:
-- moving this substitution after the static one changes the maze geometry.
local directives = require("constants.vault_directives")

local handler = {}

-- Insert only the optional inversion at the source script position; the
-- unconditional colour/material substitution stays visible in the DES.
function handler.configure(api)
    if api:one_in(5) then
        api:emit(directives.SUBST, "x = -, . = x, @- = .")
    end
end

return handler
