-- Example: D:1 cannot have an up stair; later floors choose the staircase glyph by depth position.
local directives = require("constants.vault_directives")

local handler = {}

-- D:1 cannot have an up stair; later floors choose the staircase glyph by depth position.
local function choose_hallway_stair(api)
    local stairs

    if api:depth() == 1 then
        stairs = ")}]"
    elseif api:depth_fraction() < 1 then
        stairs = "(){}[]"
    else
        stairs = "({["
    end

    api:emit(directives.SUBST, "S = " .. stairs)
end

handler.choose_hallway_stair = choose_hallway_stair

return handler
