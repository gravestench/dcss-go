local directives = require("constants.vault_directives")

local handler = {}

-- Port of builder/shops.des:464-470.
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
