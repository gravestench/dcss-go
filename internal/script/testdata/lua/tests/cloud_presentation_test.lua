local harness = require("tests.harness")
local colors = require("policy.presentation.colors")
local clouds = require("policy.presentation.clouds")
local ids = require("ids.clouds")

local test = {}

function test.run()
    local fire = clouds.get(ids.CLOUD_FIRE)
    local acid = clouds.get(ids.CLOUD_ACID)
    local rain = clouds.get(ids.CLOUD_RAIN)

    harness.equal(fire.name, "flame", "fire uses catalog source name")
    harness.equal(fire.color, colors.light_red,
        "fire retains source console appearance")
    harness.equal(acid.name, "acidic fog", "acid is visible from catalog")
    harness.equal(acid.color, colors.yellow, "source acid color")
    harness.equal(rain.name, "rain", "rain is visible from catalog")
end

return test
