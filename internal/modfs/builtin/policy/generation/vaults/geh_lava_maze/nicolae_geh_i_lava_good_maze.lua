-- The Gehenna maze alternates diagonal halves with orthogonal halves.
-- Each branch retains its paired filler substitution and helper sites.
local directives = require("constants.vault_directives")

local handler = {}

-- One source coin toss chooses all four matching quadrant operations.
function handler.configure(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "ps = x")
        api:emit(directives.SUBVAULT, "ErH : nico_lavamaze_diaghalf")
        api:emit(directives.SUBVAULT, "DqF : nico_lavamaze_diaghalf")
    else
        api:emit(directives.SUBST, "qr = x")
        api:emit(directives.SUBVAULT, "DpE : nico_lavamaze_orthhalf")
        api:emit(directives.SUBVAULT, "FsH : nico_lavamaze_orthhalf")
    end
end

return handler
