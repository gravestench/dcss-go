-- Theory of operation: A narrow central cross exposes long walls on four sides.
-- Keep its arms open so the room pass can attach chambers.
local build = require("policy.generation.layouts.vaults.build")
local motif = require("policy.generation.layouts.vaults.crosses")

local layout = {}

-- Paint the long arms first; shared build then fits DES rooms against
-- their walls and completes the stair contract.
local function layout_vaults_big_cross(api)
    return build.run(api, motif.big_cross)
end

layout.layout_vaults_big_cross = layout_vaults_big_cross

return layout
