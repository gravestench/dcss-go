-- Theory of operation: Several divisions leave a connected grid around optional blocks.
-- The DES declaration chooses this motif; the hook paints geometry.
local build = require("policy.generation.layouts.vaults.build")
local motif = require("policy.generation.layouts.vaults.grids")

local layout = {}

-- Carve the grid before tagged room selection so later rooms
-- extend its compartments without changing the layout weight.
local function layout_vaults_quadrants(api)
    return build.run(api, motif.quadrants)
end

layout.layout_vaults_quadrants = layout_vaults_quadrants

return layout
