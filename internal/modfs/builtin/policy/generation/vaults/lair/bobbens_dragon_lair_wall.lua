-- Theory of operation: the source changes its dragon-wall defenders at
-- absolute depth fourteen. The wall geometry and keyed monsters stay in DES.
local directives = require("constants.vault_directives")

local handler = {}

-- Substitute the stronger source pool only beyond the shallow band.
local function configure(api)
    if api:absolute_depth() > 13 then
        api:emit(directives.SUBST, "A = 4:1 5:9, B = 3 4:2 .:4")
    else
        api:emit(directives.SUBST, "A = 12, B = 3:2 .:3")
    end
end

handler.configure = configure

return handler
