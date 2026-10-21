-- Theory of operation: the nautilus has one stair placeholder. Its palette
-- narrows as the branch approaches its bottom so the authored shell cannot
-- point the player beyond Shoals:4.
local directives = require("constants.vault_directives")

local handler = {}

-- Select the source first, middle, or final stair alternatives.
local function configure_stairs(api)
    local stairs = "({["

    if api:depth() == 1 then
        stairs = ")}]"
    elseif api:depth_fraction() < 1 then
        stairs = "(){}[]"
    end

    api:emit(directives.SUBST, "S = " .. stairs)
end

handler.configure_stairs = configure_stairs

return handler
