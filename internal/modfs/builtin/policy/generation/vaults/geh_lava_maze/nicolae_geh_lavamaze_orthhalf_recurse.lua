-- The orthogonal half recursively fits either two corners or one side
-- flanked by two octagonal helpers.
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the source coin toss and ordered helper placements together.
function handler.configure(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "q = x")
        api:emit(directives.SUBVAULT, "DpE : nico_lavamaze_corner")
        api:emit(directives.SUBVAULT, "FrH : nico_lavamaze_corner")
    else
        api:emit(directives.SUBST, "pr = x")
        api:emit(directives.SUBVAULT, "D : nico_lavamaze_oct")
        api:emit(directives.SUBVAULT, "EqF : nico_lavamaze_side")
        api:emit(directives.SUBVAULT, "H : nico_lavamaze_oct")
    end
end

return handler
