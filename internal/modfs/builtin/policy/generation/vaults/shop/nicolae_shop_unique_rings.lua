local directives = require("constants.vault_directives")

local handler = {}

local function ring(name, plus)
    return name .. " plus:" .. plus
end

-- Port of builder/shops.des:1212-1232.
local function configure_unique_rings(api)
    local count = api:roll_dice(2, 3) + 1
    local rings = {
        ring("ring of dexterity", api:roll_dice(2, 3) - 1),
        ring("ring of intelligence", api:roll_dice(2, 3) - 1),
        ring("ring of strength", api:roll_dice(2, 3) - 1),
        ring("ring of evasion", api:roll_dice(2, 2) - 1),
        ring("ring of slaying", api:roll_dice(2, 2) - 1),
        ring("ring of protection", api:roll_dice(2, 2) - 1),
        ring("ring of dexterity", api:roll_dice(3, 2) + 4),
        ring("ring of intelligence", api:roll_dice(3, 2) + 4),
        ring("ring of strength", api:roll_dice(3, 2) + 4),
        ring("ring of evasion", api:roll_dice(1, 3) + 4),
        ring("ring of slaying", api:roll_dice(2, 3) + 3),
        ring("ring of protection", api:roll_dice(1, 3) + 4),
        "any ring randart",
        "any ring randart",
        "any ring randart",
    }
    local selected = api:subset(rings, count)

    selected[#selected + 1] = "any ring randart"

    api:emit(directives.KFEAT,
        "P = jewellery shop type:One-of-a-Kind suffix:Rings " ..
        "count:" .. (count + 1) .. " use_all ; " ..
        table.concat(selected, " | "))
end

handler.configure_unique_rings = configure_unique_rings

return handler
