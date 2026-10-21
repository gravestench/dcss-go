-- Theory of operation: Random corners change the size of this open box.
-- The DES declaration owns depth and weight; this hook paints geometry.
local build = require("policy.generation.layouts.vaults.build")
local motif = require("policy.generation.layouts.vaults.boxes")

local layout = {}

-- Draw one variable box on the layout RNG stream so the room
-- pass sees a different wall and floor balance each run.
local function layout_vaults_omnibox(api)
    return build.run(api, motif.omnibox)
end

layout.layout_vaults_omnibox = layout_vaults_omnibox

return layout
