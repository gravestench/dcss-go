-- Theory of operation: source minitemple has fourteen possible B cells.
-- Its selected overflow group keeps only the scheduled number and turns
-- remaining B cells into decorative wall glyphs before terrain is built.
local count = require("policy.generation.vaults.altar.count")
local directives = require("constants.vault_directives")

local handler = {}

-- The explicit count makes this map independent of DES loading order.
local function arrange_altars(api)
    local selected = count.selected(api, 2, 14)

    api:emit(directives.NSUBST,
        "B : " .. selected .. ":B / *:x")
end

handler.arrange_altars = arrange_altars

return handler
