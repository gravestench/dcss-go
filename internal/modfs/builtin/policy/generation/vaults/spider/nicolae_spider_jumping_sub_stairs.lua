-- The jumping stair child marks one slot with source stair glyphs.
-- Its separate shared setup hook later adds spiders and island water.
local directives = require("constants.vault_directives")

local handler = {}

-- First, middle, and last Spider floors use different source options.
local function stairs(api)
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

handler.stairs = stairs

return handler
