-- A cloud mod replaces Fire and adds Silver Haze; lookup and presentation
-- must both use those effective definitions after overlay loading.

local categories = require("constants.catalog")
local content = require("policy.catalog")
local harness = require("tests.harness")
local ids = require("ids.clouds")
local presentation = require("policy.presentation.clouds")

local test = {}

-- Inspect both a same-path override and a new cloud ID, then ask presentation
-- for each to prove the effective catalog is shared across consumers.
function test.run()
    local fire = content.get(categories.CLOUDS, ids.CLOUD_FIRE)
    local custom = content.get(categories.CLOUDS, ids.CLOUD_TEST_CUSTOM)

    harness.equal(fire.name, "violet flame", "same-path cloud override")
    harness.equal(custom.name, "silver haze", "mod-added cloud")
    harness.truthy(custom.opaque, "mod cloud opacity")
    harness.equal(presentation.get(ids.CLOUD_FIRE).name,
        "violet flame", "presentation reads the effective override")
    harness.equal(presentation.get(ids.CLOUD_TEST_CUSTOM).name,
        "silver haze", "presentation reads a mod-added cloud")
end

return test
