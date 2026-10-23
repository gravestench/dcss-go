-- One sparse mod can add an Abyss room and replace one base file. Both go
-- through the ordinary layered DES catalog, so modders never edit a list
-- of known Abyss IDs in Go or Lua to make their content discoverable.
local des = require("policy.generation.vaults.des")
local harness = require("tests.harness")
local vaults = require("policy.generation.vaults.catalog")
local regular = require("policy.generation.vaults.regular")
local used = require("policy.generation.vaults.used")
local branches = require("ids.branches")
local abyss = require("constants.abyss")

local test = {}

-- The additional room contributes a new ID while an existing relative path
-- keeps its ID but supplies the mod's entire replacement definition.
function test.run()
    local paths = mod.paths("vaults/abyss", ".des")
    local extra_path = "vaults/abyss/zz_modded_abyss_echo.des"
    local replaced_path = "vaults/abyss/abyss_fake_exit.des"
    local extra = des.parse(extra_path, mod.read(extra_path))
    local replaced = des.parse(replaced_path, mod.read(replaced_path))

    harness.equal(#paths, 92, "one added Abyss map joins the catalog")
    harness.equal(vaults.get(extra.id).id, extra.id)
    harness.equal(vaults.get(replaced.id).id, replaced.id)
    harness.equal(#replaced.rows[1], 2,
        "same-path mod replaces the base geometry")

    local candidates = regular.candidates({
        branch_id = branches.BRANCH_ABYSS,
        depth = 1,
        branch_bottom = 7,
        absolute_depth = 16,
        branch_vault_family = abyss.VAULT_FAMILY,
        regular_extra_only = true,
        used = used.new({}),
    })
    local selectable = false

    for _, candidate in ipairs(candidates) do
        if candidate.definition.id == extra.id then
            selectable = true
        end
    end

    harness.truthy(selectable,
        "one-file addition joins the production Abyss draw")
end

return test
