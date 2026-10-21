-- Theory of operation: Alternating chamber attachments make a winding corridor.
-- The DES declaration chooses this shape; the hook paints its cells.
local build = require("policy.generation.layouts.vaults.build")
local motif = require("policy.generation.layouts.vaults.mazes")

local layout = {}

-- Paint the winding route first; shared room placement preserves
-- its accepted connections while adding source rooms.
local function layout_vaults_maze_snakey(api)
    return build.run(api, motif.snakey)
end

layout.layout_vaults_maze_snakey = layout_vaults_maze_snakey

return layout
