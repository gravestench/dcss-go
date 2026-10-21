-- Theory of operation: at a branch bottom, this forest points its stair
-- back upward. On earlier floors the authored down stair stays in the map.
local directives = require("constants.vault_directives")

local handler = {}

-- The source compares local depth with branch length before swapping glyphs.
local function configure(api)
    if api:depth_fraction() == 1 then
        api:emit(directives.SUBST, ") = (")
    end
end

handler.configure = configure

return handler
