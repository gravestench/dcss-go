-- Theory of operation: this compact overflow room has five candidate O
-- positions. Unselected positions become the source's decorative l glyph.
local count = require("policy.generation.vaults.altar.count")
local directives = require("constants.vault_directives")

local handler = {}

-- Emit the selected altar count before the l glyph's ecumenical feature rule.
local function arrange_altars(api)
    local selected = count.selected(api, 3, 5)

    api:emit(directives.NSUBST,
        "O = " .. selected .. ":B / *:l")
end

handler.arrange_altars = arrange_altars

return handler
