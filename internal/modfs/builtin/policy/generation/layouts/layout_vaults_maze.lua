-- Theory of operation: Connected chambers grow from a central seed into a branching maze.
-- The DES declaration chooses this motif; the hook paints its cells.
local build = require("policy.generation.layouts.vaults.build")
local motif = require("policy.generation.layouts.vaults.mazes")

local layout = {}

-- Grow the ordinary maze before fitting tagged rooms, then let
-- the shared stage protect accepted connectors and add stairs.
local function layout_vaults_maze(api)
    return build.run(api, motif.ordinary)
end

layout.layout_vaults_maze = layout_vaults_maze

return layout
