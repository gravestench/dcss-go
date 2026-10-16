local directives = require("constants.vault_directives")

local handler = {}

-- Port of arrival/small.des:517-526.
local function choose_spiral_entrance(api)
    if api:one_in(4) then
        api:emit(directives.SUBST, "ABCDEFGHJ = +")
        api:emit(directives.SUBST, "abcdefghj = x")
    else
        api:emit(directives.SUBST, "a=A, b=B, c=C, d=D, e=E, f=F, g=G, h=H, j=J")
        api:emit(directives.NSUBST, "A = 1:+ / *:X , B = 1:+ / *:X , C = 1:+ / *:X , D = 1:+ / *:X")
        api:emit(directives.NSUBST, "E = 1:+ / *:X , F = 1:+ / *:X , G = 1:+ / *:X , H = 1:+ / *:X")
        api:emit(directives.NSUBST, "J = 1:+ / *:X")
        api:emit(directives.SUBST, "X:Xxxx+, X=xx+")
    end
end

handler.choose_spiral_entrance = choose_spiral_entrance

return handler
