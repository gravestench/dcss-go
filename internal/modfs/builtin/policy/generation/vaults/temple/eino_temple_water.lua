-- Water outside this Temple map is part of its source geography. Store that
-- border decision with the selected map rather than defaulting to rock.
local fill = require("constants.vault_border_fill")
local effects = require("constants.vault_effects")

local handler = {}

-- The placement pass applies this source open-sea border after the MAP is
-- positioned, leaving its internal water substitutions in DES.
local function configure(api)
    api:record(effects.BORDER_FILL, {
        style = fill.OPEN_SEA,
    })
end

handler.configure = configure

return handler
