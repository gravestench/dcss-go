-- A free item selection must survive a save before its confirmation.
-- The entity reference is revalidated before any timed action begins.
local component = require("constants.component")

register.component({
    id = component.LUGONU_BLESS_CHOICE,
    version = 1,
    fields = {
        item = {
            type = "entity",
        },
    },
})
