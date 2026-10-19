-- Example: ctx:get(actor, component.PARALYSIS) reads the remaining paralysis delay.
-- beam.cc:apply_bolt_paralysis and mon-ench.cc:ENCH_PARALYSIS.
local component = require("constants.component")
local state = {}

-- Paralysis duration is stored on monsters so later turns can skip their actions.
register.component{
    id = component.PARALYSIS,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

return state
