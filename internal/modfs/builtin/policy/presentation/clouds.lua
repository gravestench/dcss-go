local colors = require("policy.presentation.colors")
local ids = require("policy.magic.effects.zaps.ids")

local clouds = {}

local definitions = {
    [ids.cloud.FIRE] = {
        name = "flame",
        color = colors.light_red,
    },
    [ids.cloud.COLD] = {
        name = "freezing vapour",
        color = colors.light_cyan,
    },
    [ids.cloud.EMBERS] = {
        name = "embers",
        color = colors.red,
    },
    [ids.cloud.MEPHITIC] = {
        name = "noxious fumes",
        color = colors.green,
    },
    [ids.cloud.DUST] = {
        name = "dust",
        color = colors.brown,
    },
    [ids.cloud.TLOC_ENERGY] = {
        name = "translocational energy",
        color = colors.magenta,
    },
    [ids.cloud.POISON] = {
        name = "poison gas",
        color = colors.light_green,
    },
    [ids.cloud.GREY_SMOKE] = {
        name = "grey smoke",
        color = colors.light_grey,
    },
    [ids.cloud.BLUE_SMOKE] = {
        name = "blue smoke",
        color = colors.light_blue,
    },
    [ids.cloud.BLACK_SMOKE] = {
        name = "black smoke",
        color = colors.dark_grey,
    },
    [ids.cloud.PURPLE_SMOKE] = {
        name = "purple smoke",
        color = colors.magenta,
    },
}

function clouds.get(kind_id)
    local definition = definitions[kind_id]

    if not definition then
        error("cloud " .. tostring(kind_id) .. " has no presentation")
    end

    return definition
end

return clouds
