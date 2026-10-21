-- The source picks either Uskayaw's animated weapons or Qazlal's
-- elementals before its common crowd-size substitution runs.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit only the chosen altar's matching defenders and terrain.
local function configure(api)
    if api:one_in(2) then
        api:emit(directives.KMONS,
            "1 = dancing weapon ; any weapon")
        api:emit(directives.KMONS,
            "_ = dancing weapon ; any weapon good_item | " ..
            "any weapon randart w:5")
        api:emit(directives.KFEAT, "_ = altar_uskayaw")
    else
        api:emit(directives.KMONS,
            "1_ = fire elemental / water elemental / " ..
            "air elemental / earth elemental")
        api:emit(directives.KFEAT, "_ = altar_qazlal")
    end
end

handler.configure = configure

return handler
