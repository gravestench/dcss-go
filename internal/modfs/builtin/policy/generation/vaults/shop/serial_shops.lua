-- Example: Place a rare bazaar entry before the ordinary shops; its probability rises with absolute depth.
local directives = require("constants.vault_directives")

local handler = {}

-- Place a rare bazaar entry before the ordinary shops; its probability rises with absolute depth.
local function shop_count(api)
    if api:chance(5, 6) then
        return 1
    end

    return api:random_range(2, 5)
end

-- Draw shop count before the depth-sensitive bazaar chance.
local function place_serial_shops(api)
    local count = shop_count(api)
    local depth = api:absolute_depth()

    if depth > 10 and depth <= 27 and
        api:one_in(30 - (depth - 1)) then
        count = count - api:place_maps("bzr_entry", 1)
    end

    api:place_maps("shop", count)
end

handler.place_serial_shops = place_serial_shops

return handler
