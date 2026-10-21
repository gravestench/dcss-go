-- The three source Vaults room files provide the reusable pieces from which
-- primary layouts are built. Keeping their full named corpus in the catalog
-- lets layout policy choose rooms without hard-coded IDs or load order.
local catalog = require("policy.generation.vaults.catalog")
local des = require("policy.generation.vaults.des")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local item_specs = require("policy.generation.vaults.specs.item")
local resolve = require("policy.generation.vaults.specs.resolve")

local test = {}

-- Require every dedicated room to parse and register, including rooms whose
-- source tag was supplied by the old shared setup function.
function test.run()
    local paths = mod.paths("vaults/vaults_room", ".des")
    local tagged = {
        vaults_room = 0,
        vaults_hard = 0,
        vaults_empty = 0,
    }

    harness.equal(#paths, 250, "all dedicated source Vaults rooms are committed")

    for _, path in ipairs(paths) do
        local definition = des.parse(path, mod.read(path))

        harness.equal(catalog.get(definition.id).path, path,
            definition.id .. " is registered from its own DES file")

        for tag in pairs(tagged) do
            if definition.tags[tag] then
                tagged[tag] = tagged[tag] + 1
            end
        end
    end

    harness.equal(tagged.vaults_room, 99,
        "all source standard rooms are eligible")
    harness.equal(tagged.vaults_hard, 58,
        "all source hard rooms are eligible")
    -- One empty-corpus definition is a tagged SUBVAULT helper, not an
    -- independent room candidate. It remains in the 250-file corpus.
    harness.equal(tagged.vaults_empty, 92,
        "source empty rooms exclude the helper-only definition")

    local box = catalog.get("st_greater_box_1")
    local has_draconian = false

    for _, operation in ipairs(box.operations) do
        has_draconian = has_draconian or
            operation.argument:find("base draconian", 1, true) ~= nil
    end

    harness.truthy(has_draconian,
        "greater boxes retain their random base-draconian threat")

    local unique_room = catalog.get("minmay_guarded_unrand_guard_vaults")
    local selected = item_specs.parse("glaive_of_the_guard no_pickup", {
        path = unique_room.path,
        vault_id = unique_room.id,
        line = 7,
        directive = "ITEM",
        glyph = "?",
    })[1][1]
    local item = resolve.item(nil, selected, 14, {
        path = unique_room.path,
        vault_id = unique_room.id,
        line = 7,
        directive = "ITEM",
        glyph = "?",
    })

    harness.equal(item.unique_id, "UNRAND_GUARD",
        "named source artefact resolves to its unique catalog ID")
    harness.truthy(item.no_pickup, "source pickup restriction survives resolution")

    local statue = catalog.get("kennysheep_vaults_gozag_temple")
    local records = {}
    local api = {}

    -- Capture the same typed feature record emitted by the production hook;
    -- a minimal sink is enough because this test checks the hook contract.
    function api:record(kind, arguments)
        records[#records + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    hooks.run(statue, "features.golden_statue", api)
    harness.equal(records[1].kind, effects.FEATURE_NAME,
        "Gozag room keeps its authored statue name")
end

return test
