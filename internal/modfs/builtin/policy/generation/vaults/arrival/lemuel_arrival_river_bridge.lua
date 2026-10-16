local directives = require("constants.vault_directives")

local handler = {}

-- Port of arrival/twisted.des:563-565.
local function choose_pool_fixup(api)
    if not api:validating() and api:coinflip() then
        api:emit(directives.TAGS, "no_pool_fixup")
    end
end

handler.choose_pool_fixup = choose_pool_fixup

return handler
