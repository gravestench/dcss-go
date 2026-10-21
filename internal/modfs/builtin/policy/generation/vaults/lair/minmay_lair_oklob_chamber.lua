-- Theory of operation: this oklob chamber scales from a small central
-- encounter into a larger one as absolute depth and its source draw rise.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit the paired size and plant-lottery rules at the source script site.
local function configure(api)
    local size = api:roll(10) + api:absolute_depth() - 10

    if size > 8 then
        api:emit(directives.SUBST, "'`\" = ., yza = x, XYZ = ?, 1234 = p")
        api:emit(directives.NSUBST, "? = 1:% / 4:P / * = ?")
    elseif size > 6 then
        api:emit(directives.SUBST, "'` = ., XY = ?, yzZ4 = x, 123 = p")
        api:emit(directives.NSUBST, "? = 1:% / 3:P / * = ?")
    elseif size > 3 then
        api:emit(directives.SUBST, "' = ., X = ?, 3yY = x, 12 = p")
        api:emit(directives.NSUBST, "? = 1:% / 2:P / * = ?")
    else
        api:emit(directives.SUBST, "X2 = x, 1 = p")
        api:emit(directives.NSUBST, "? = 1:% / 1:P / * = ?")
    end
end

handler.configure = configure

return handler
