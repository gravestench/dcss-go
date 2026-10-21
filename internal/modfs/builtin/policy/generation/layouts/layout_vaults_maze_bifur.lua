-- Theory of operation: Two opposite arms branch into separate lobes.
-- The DES declaration chooses this shape; the hook paints its cells.
local build = require("policy.generation.layouts.vaults.build")
local motif = require("policy.generation.layouts.vaults.mazes")

local layout = {}

-- Paint both lobes before fitting DES rooms so later placement
-- does not substitute generic Dungeon geometry.
local function layout_vaults_maze_bifur(api)
    return build.run(api, motif.bifurcated)
end

layout.layout_vaults_maze_bifur = layout_vaults_maze_bifur

return layout
