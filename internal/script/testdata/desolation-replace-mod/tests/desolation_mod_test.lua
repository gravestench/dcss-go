-- An overlay file with the same relative path replaces one floor while
-- keeping its stable ID. The selector and generator see the replacement.
local harness = require("tests.harness")
local level = require("policy.generation.desolation.level")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Verify the effective catalog and the real staged-level builder agree.
function test.run()
    local map = vaults.get("desolation_of_salt")

    harness.equal(#map.rows, 3, "overlay replaces the source rows")
    harness.equal(map.rows[2], "..<..",
        "overlay exit survives effective VFS loading")

    local value = 17
    local context = {}

    -- Match the builder's two-word random draw interface for this overlay.
    function context:random_u64()
        value = (value * 48271) % 2147483647

        return 0, value
    end

    -- Keep the same bounded draw used by the production floor builder.
    function context:random(_stream, bound)
        self:random_u64()

        return value % bound
    end

    local generated = level.generate(context, {
        layout_id = map.id,
    })

    harness.equal(generated.level.vault_id, map.id,
        "replacement floor keeps the selected ID")
end

return test
