local directives = require("constants.vault_directives")

local handler = {}

-- Port of builder/shops.des:886-919.
local function configure_chei_stock(api)
    local plate_plus = 3 + api:roll(3) + api:roll(8)

    if api:chance(21 + api:absolute_depth(), 300) then
        plate_plus = plate_plus + api:roll(3)
    end

    plate_plus = math.min(10, plate_plus)

    local crystal_plus = api:roll(6)
    local choices = {
        "black knight's barding",
        "hat of pondering",
        "crystal plate armour ego:ponderousness plus:" .. crystal_plus,
        "plate armour ego:ponderousness plus:" .. plate_plus,
    }
    local count = api:roll(2) + 1
    local selected = api:subset(choices, count)

    api:emit(directives.KFEAT,
        "S = armour shop name:Cheibriados type:Comfort suffix:Zone " ..
        "use_all ; " .. table.concat(selected, " | "))
end

handler.configure_chei_stock = configure_chei_stock

return handler
