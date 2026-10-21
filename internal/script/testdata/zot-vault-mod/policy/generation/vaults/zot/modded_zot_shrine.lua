-- The matching family and filename let a sparse mod give its new DES map
-- a source-position decision without registering anything in Go.
local directives = require("constants.vault_directives")

local shrine = {}

-- Keep this fixture's result obvious: the emitted no-op substitution proves
-- that the layered handler was found and invoked at its declaration site.
local function configure(api)
    api:emit(directives.SUBST, ". = .")
end

shrine.configure = configure

return shrine
