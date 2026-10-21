-- Theory of operation: the crossing's S placeholder offers different
-- equipment glyph sets at branch entry, middle floors, and the bottom.
-- The source depth fraction is local depth divided by branch bottom.
local directives = require("constants.vault_directives")

local handler = {}

-- The first-floor case precedes the fraction check. Otherwise every
-- nonbottom floor uses the broad set and the bottom uses the final set.
function handler.configure(api)
    local glyphs

    if api:depth() == 1 then
        glyphs = ")}]"
    elseif api:depth_fraction() < 1 then
        glyphs = "(){}[]"
    else
        glyphs = "({["
    end

    api:emit(directives.SUBST, "S = " .. glyphs)
end

return handler
