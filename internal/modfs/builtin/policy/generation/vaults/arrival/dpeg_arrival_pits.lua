-- Example: Failed one-in-four, one-in-three, and one-in-two tests each consume a fresh layout draw.
local directives = require("constants.vault_directives")

local handler = {}

-- Failed one-in-four, one-in-three, and one-in-two tests each consume a fresh layout draw.
local function choose_pit_layout(api)
    if api:one_in(4) then
        api:emit(directives.SUBST, "Yy=w, Zz=l, Xx\"'=b")
        api:emit(directives.NSUBST, "U = 1:} / *:{")
    elseif api:one_in(3) then
        api:emit(directives.SUBST, "U=., Yy=w, Zz=l")
        api:emit(directives.SHUFFLE, "x_/'\"")
        api:emit(directives.SUBST, "x=+, '=b, \":\".b")
        api:emit(directives.NSUBST, "X = 1:} / *:{")
    elseif api:one_in(2) then
        api:emit(directives.SUBST, "U=., Zz=l, Xx\"'=b")
        api:emit(directives.NSUBST, "Y = 1:} / *:{, y = 1:. / *:w")
    else
        api:emit(directives.SUBST, "U=., Yy=w, Xx\"'=b")
        api:emit(directives.NSUBST, "Z = 1:} / *:{, z = 1:. / *:l")
    end
end

handler.choose_pit_layout = choose_pit_layout

return handler
