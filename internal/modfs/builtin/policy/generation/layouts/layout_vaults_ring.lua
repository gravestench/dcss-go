-- Theory of operation: A five-cell corridor wraps a solid inner block.
-- Its inner and outer walls give the room pass two attachment sides.
local build = require("policy.generation.layouts.vaults.build")
local motif = require("policy.generation.layouts.vaults.boxes")

local layout = {}

-- Paint the ring before inserting DES rooms; the shared stage
-- protects the ring's accepted connectors and completes stairs.
local function layout_vaults_ring(api)
    return build.run(api, motif.ring)
end

layout.layout_vaults_ring = layout_vaults_ring

return layout
