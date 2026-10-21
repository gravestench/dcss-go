-- Source: crawl-ref/source/dat/des/branches/geh.des; geh_grunt.
-- Each method runs at its matching source script position in the DES.
local shared = require("policy.generation.vaults.geh_end.shared")

local handler = {}

-- Keep the Serpent choice and unique check in saved shared run state.
function handler.serpent(api)
    shared.serpent(api)
end

-- The four lava-bound maps fill uncovered edges with endless lava.
function handler.border_fill(api)
    shared.border_fill(api)
end

-- Apply the source Geh:$ rune, palette, and feature names.
function handler.setup(api)
    shared.setup(api)
end

return handler
