local directives = require("constants.vault_directives")

local handler = {}

-- Port of arrival/small.des:3098-3102.
local function choose_settlement_layout(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "de = ', f = t, gh = ., ij = -, kpqr = x, s = @, uy = A")
    else
        api:emit(directives.SUBST, "dhjsy = x, gfru = -, ep = A, iq = ., k = @")
    end
end

handler.choose_settlement_layout = choose_settlement_layout

return handler
