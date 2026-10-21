-- Theory of operation: one of three source wall/floor sets opens the
-- squiggle maze. The first choice has its own one-in-three draw; if it
-- fails, a coin toss distinguishes the other two source alternatives.
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the two draws in source order. The later SHUFFLE and CLEAR lines
-- remain in DES, so this hook only chooses the conditional substitutions.
function handler.configure(api)
    if api:one_in(3) then
        api:emit(directives.SUBST, "DHK = x, EFJ = .")
    elseif api:coinflip() then
        api:emit(directives.SUBST, "EHJ = x, DFK = .")
    else
        api:emit(directives.SUBST, "FJK = x, DEH = .")
    end
end

return handler
