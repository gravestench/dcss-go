-- This Temple varies its altar count while retaining the freezing cloud
-- markers in DES. The source removes surplus B glyphs with NSUBST.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Replace exactly the selected number of B cells before cloud markers
-- bind to the finished map, preserving the source substitution order.
local function configure(api)
    api:emit(directives.NSUBST,
        "B = " .. count.selected(api) .. ":B / *:'")
end

handler.configure = configure

return handler
