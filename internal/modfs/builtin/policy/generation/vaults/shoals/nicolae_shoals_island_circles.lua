-- Theory of operation: the island rings need stairs in different directions
-- on the first, middle, and final Shoals floors. The DES owns their geometry;
-- this hook only supplies the source depth-dependent glyph palette.
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the first-floor downward routes and last-floor upward routes distinct.
local function configure_stairs(api)
    local stairs = "]})[{("

    if api:depth() == 1 then
        stairs = "]})"
    elseif api:depth() == api:branch_bottom() then
        stairs = "[{("
    end

    api:emit(directives.SUBST, "s = " .. stairs)
end

handler.configure_stairs = configure_stairs

return handler
