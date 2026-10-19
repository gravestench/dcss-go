-- player.cc:corrosion_amount; saved duration and accumulated stacks.
local component = require("constants.component")

register.component({
    id = component.CORROSION,
    version = 1,
    -- Duration and accumulated stacks are separate: another corrosion hit can strengthen an active penalty.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
        stacks = {
            type = "int64",
            default = 0,
        },
    },
})
