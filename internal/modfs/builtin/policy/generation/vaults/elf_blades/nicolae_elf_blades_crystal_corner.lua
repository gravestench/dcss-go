-- The crystal-corner Hall either keeps its three weapon wings walled or
-- shuffles two of them into a more open arrangement before drawing MAP.
local directives = require("constants.vault_directives")

local handler = {}

-- Use the source one-in-four decision ahead of the common Hall SHUFFLE.
local function configure(api)
    if api:one_in(4) then
        api:emit(directives.SUBST, "FJH = b")
    else
        api:emit(directives.SHUFFLE, "FH")
        api:emit(directives.SUBST, "FJ = ., H : bb.")
    end
end

handler.configure = configure

return handler
