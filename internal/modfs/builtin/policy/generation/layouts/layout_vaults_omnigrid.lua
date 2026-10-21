-- Theory of operation: Recursive boxes leave irregular corridors around wall islands.
-- The DES declaration chooses this motif; the hook paints geometry.
local build = require("policy.generation.layouts.vaults.build")
local motif = require("policy.generation.layouts.vaults.grids")

local layout = {}

-- Carve nested boxes before room selection so the shared pass
-- can protect their corridors while attaching source rooms.
local function layout_vaults_omnigrid(api)
    return build.run(api, motif.omnigrid)
end

layout.layout_vaults_omnigrid = layout_vaults_omnigrid

return layout
