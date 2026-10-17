local directives = require("constants.vault_directives")

local handler = {}

-- Port of builder/shops.des:1025-1030.
local function configure_clearance_sale(api)
    local greed = api:roll_dice(9, 2) - 9
    local count = api:roll_dice(6, 2) - 5

    api:emit(directives.KFEAT,
        "S = general shop type:CLEARANCE_SALE! " ..
        "greed:" .. greed .. " count:" .. count)
end

handler.configure_clearance_sale = configure_clearance_sale

return handler
