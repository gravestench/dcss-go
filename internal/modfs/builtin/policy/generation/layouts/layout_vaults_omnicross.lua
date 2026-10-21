-- Theory of operation: Variable floor strips meet at one junction.
-- The DES declaration chooses this motif; the hook paints geometry.
local build = require("policy.generation.layouts.vaults.build")
local motif = require("policy.generation.layouts.vaults.crosses")

local layout = {}

-- Draw the crossing strips first so tagged rooms can fit
-- against the remaining wall without owning the crossing rule.
local function layout_vaults_omnicross(api)
    return build.run(api, motif.omnicross)
end

layout.layout_vaults_omnicross = layout_vaults_omnicross

return layout
