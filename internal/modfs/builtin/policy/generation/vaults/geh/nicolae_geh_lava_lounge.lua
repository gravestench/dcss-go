-- The lounge varies its S glyph at entry, intermediate, and final depth.
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the first-floor check before the depth-fraction branch from source.
function handler.configure(api)
    local glyphs

    if api:depth() == 1 then
        glyphs = "}G"
    elseif api:depth_fraction() < 1 then
        glyphs = "{}GG"
    else
        glyphs = "{G"
    end

    api:emit(directives.SUBST, "S = " .. glyphs)
end

return handler
