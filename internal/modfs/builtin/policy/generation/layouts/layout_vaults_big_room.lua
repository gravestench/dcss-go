-- Theory of operation: A padded open hall reserves thick surrounding wall for chambers.
-- The DES declaration owns depth and weight; this hook paints only the hall.
local build = require("policy.generation.layouts.vaults.build")
local motif = require("policy.generation.layouts.vaults.boxes")

local layout = {}

-- Leave the broad center walkable before the shared room pass
-- cuts chambers into the outer wall.
local function layout_vaults_big_room(api)
    return build.run(api, motif.big_room)
end

layout.layout_vaults_big_room = layout_vaults_big_room

return layout
