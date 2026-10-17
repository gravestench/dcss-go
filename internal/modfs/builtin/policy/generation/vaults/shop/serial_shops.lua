local directives = require("constants.vault_directives")

local handler = {}

-- Port of the shared builder/shops.des prelude and lines 71-84.
local function shop_count(api)
    if api:chance(5, 6) then
        return 1
    end

    return api:random_range(2, 5)
end

local function place_serial_shops(api)
    local count = shop_count(api)
    local depth = api:absolute_depth()

    if depth > 10 and depth <= 27 and
        api:one_in(30 - (depth - 1)) then
        api:place_maps("bzr_entry", 1)
        count = count - 1
    end

    api:place_maps("shop", count)
end

handler.place_serial_shops = place_serial_shops

return handler
