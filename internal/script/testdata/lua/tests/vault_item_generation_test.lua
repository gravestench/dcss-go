-- Gold is the fixed source kind.

local classes = require("ids.object_classes")
local harness = require("tests.harness")
local ids = require("ids.items")
local quality = require("constants.vault_item_quality")
local names = require("constants.vault_item_requests")
local requests = require("policy.generation.vaults.specs.random_items")
local item_specs = require("policy.generation.vaults.specs.item")
local resolve = require("policy.generation.vaults.specs.resolve")

local test = {}

-- Source shorthand must preserve quality and depth until the generator picks a subtype.
local function descriptors_preserve_source_request()
    local ordinary = requests.describe("random_item", 2)
    local star = requests.describe("*", 2)
    local gold = requests.describe("random_gold", 2)

    harness.equal(ordinary.kind_id, classes.OBJ_RANDOM,
        "random subtype waits for item generator")
    harness.equal(ordinary.quality, quality.ORDINARY,
        "ordinary quality")
    harness.equal(star.depth, 9, "source star depth boost")
    harness.equal(star.quality, quality.STAR, "star quality")
    harness.equal(gold.kind_id, ids.OBJ_GOLD,
        "gold is the fixed source kind")
end

-- A source quality modifier is parsed separately from the random-item
-- name; the resolver must carry it into the saved placement request.
local function source_good_item_keeps_quality()
    local site = {
        path = "vaults/snake/cheibrodos_snake_ritualist_ritual.des",
        vault_id = "cheibrodos_snake_ritualist_ritual",
        line = 10,
        directive = "KITEM",
        glyph = "-",
    }
    local selected = item_specs.term(names.ANY_GOOD_ITEM, site)
    local resolved = resolve.item({}, selected, 16, site)

    harness.equal(resolved.kind_id, classes.OBJ_RANDOM,
        "source good item remains a generated subtype")
    harness.equal(resolved.quality, quality.GOOD,
        "source good_item modifier reaches generation")
end

-- Snake's scaly vault uses DES marker:weight spelling rather than w:.
-- Its alternative weights must reach the same reservoir draw as w: terms.
local function weighted_item_markers_keep_source_weights()
    local site = {
        path = "vaults/snake/nicolae_snake_scaly_snakehead.des",
        vault_id = "nicolae_snake_scaly_snakehead",
        line = 12,
        directive = "KITEM",
        glyph = "2",
    }
    local options = item_specs.parse(
        "%:15 / * / |:5 / nothing w:5", site)[1]

    harness.equal(options[1].name, "%", "first source marker")
    harness.equal(options[1].weight, 15, "first marker source weight")
    harness.equal(options[3].name, "|", "third source marker")
    harness.equal(options[3].weight, 5, "third marker source weight")
end

-- Source Snake requests specify jewellery class and sometimes its ring or
-- amulet half. The later item roller must receive that class, not a name.
local function jewellery_descriptors_preserve_class()
    for _, name in ipairs({
        names.ANY_AMULET,
        names.ANY_RING,
        names.ANY_JEWELLERY,
    }) do
        local described = requests.describe(name, 16)

        harness.equal(described.kind_id, classes.OBJ_RANDOM,
            name .. " remains a random subtype")
        harness.equal(described.class_id, classes.OBJ_JEWELLERY,
            name .. " uses jewellery generation")
    end

    harness.equal(requests.describe(names.ANY_MAGICAL_STAFF, 16).class_id,
        classes.OBJ_STAVES, "source Snake magical staff class")
end

-- Check random, starred, and fixed-gold request descriptors together.
function test.run()
    descriptors_preserve_source_request()
    jewellery_descriptors_preserve_class()
    source_good_item_keeps_quality()
    weighted_item_markers_keep_source_weights()
end

return test
