-- Theory of operation: some source Lair entrances substitute walls and
-- hazards around the keyed O stair. Reject a candidate unless that final
-- local geometry still gives the player a traversable path to an edge.
local paths = require("policy.generation.vaults.exit_paths")

local handler = {}

-- Search from the substituted O cell, since an authored source coordinate
-- is no longer reliable after NSUBST and SHUFFLE have run.
local function has_exit(api)
    return paths.has_exit_from_glyph(api.cells, "O")
end

handler.has_exit = has_exit

return handler
