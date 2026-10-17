local des = require("policy.generation.vaults.des")
local catalog = require("policy.generation.vaults.catalog")
local directives = require("constants.vault_directives")
local harness = require("tests.harness")

local test = {}

function test.run()
    local paths = mod.paths("vaults/shop", ".des")

    harness.equal(#paths, 70, "pinned shop vault count")

    for _, path in ipairs(paths) do
        local vault = des.parse(path, mod.read(path))

        harness.truthy(vault.id ~= nil, "shop vault has a name")
        harness.equal(catalog.get(vault.id).id, vault.id,
            "shop vault is registered")
    end

    local serial = catalog.get("serial_shops")
    local post_place = false

    harness.equal(#serial.rows, 0, "serial controller has an empty map")

    for _, operation in ipairs(serial.operations) do
        if operation.kind == directives.HOOK_POST_PLACE then
            post_place = true
        end
    end

    harness.truthy(post_place, "serial shop post-place hook is retained")
end

return test
