-- Theory of operation: one source draw chooses the clearing size and the
-- density of fruit, plants, and obstacles in an authored field.
local directives = require("constants.vault_directives")

local handler = {}

-- Keep three source weight bands; the geometry lives in its DES MAP.
local function configure(api)
    local size = api:roll(9)

    if size > 7 then
        api:emit(directives.SUBST,
            "'`\"- = ^:20 ~:15 ., . = d:3 .:150 1:10 2:4")
    elseif size > 3 then
        api:emit(directives.SUBST,
            "\"` = ^:20 ~:15 ., . = d:5 .:50 1:8 2:4")
    else
        api:emit(directives.SUBST,
            "'\" = ^:20 ~:15 ., . = d:5 .:50 1:8 2:4")
    end
end

handler.configure = configure

return handler
