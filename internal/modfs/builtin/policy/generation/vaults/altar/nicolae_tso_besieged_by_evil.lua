-- Theory of operation: The Shining One's altar is besieged by minor evil.
-- At absolute depth five, its altar guardian's imp pool widens; the nearby
-- source skeleton and zombie pools remain fixed in the .des declaration.
local directives = require("constants.vault_directives")

local handler = {}

-- Only the keyed altar guardian changes with depth.
local function choose_imp(api)
    if api:absolute_depth() <= 4 then
        api:emit(directives.KMONS,
            "_ = crimson imp / white imp w:5")
    else
        api:emit(directives.KMONS,
            "_ = crimson imp / white imp / shadow imp / iron imp / quasit")
    end
end

handler.choose_imp = choose_imp

return handler
