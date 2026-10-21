-- The webbed stair vault changes its s placeholder on Spider:1,
-- Spider:4, and the middle floors. The DES owns every other directive.
local directives = require("constants.vault_directives")

local handler = {}

-- Source checks the first floor before the bottom floor, then mixes
-- all stair glyphs on intervening floors.
local function configure(api)
    local glyphs

    if api:depth() == 1 then
        glyphs = "]})"
    elseif api:depth() == api:branch_bottom() then
        glyphs = "[{("
    else
        glyphs = "]})[{("
    end

    api:emit(directives.SUBST, "s = " .. glyphs)
end

handler.configure = configure

return handler
