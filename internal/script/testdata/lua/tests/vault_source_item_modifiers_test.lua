-- These source item requests appear in committed overflow maps. Parse the
-- real DES expressions so catalog additions cannot silently drop modifiers.
local catalog = require("policy.generation.altar.catalog")
local classes = require("ids.object_classes")
local harness = require("tests.harness")
local item_specs = require("policy.generation.vaults.specs.item")
local random_books = require("policy.item_generation.random_books")
local component = require("constants.component")
local item_ids = require("ids.items")
local items = require("policy.catalog")
local schools = require("constants.spell_schools")
local quality = require("constants.vault_item_quality")
local resolve = require("policy.generation.vaults.specs.resolve")

local test = {}

-- Use the authored declaration and its source site, rather than copying a
-- synthetic spelling of each item into this test.
local function source_item(id, wanted)
    local definition = catalog.get(id)

    for _, operation in ipairs(definition.operations) do
        if operation.argument and operation.argument:find(wanted, 1, true) then
            return operation.argument, {
                path = definition.path,
                vault_id = id,
                line = operation.line,
                directive = operation.kind,
            }
        end
    end

    error(id .. " has no source item containing " .. wanted)
end

-- The random scroll and star-weapon requests must keep their class and
-- quality before the live item-generation stream chooses a subtype.
function test.run()
    local scroll, scroll_site = source_item("zin_scriptorium", "any scroll")
    local scroll_choice = item_specs.parse(scroll, scroll_site)[1][1]
    local scroll_request = resolve.item({}, scroll_choice, 5, scroll_site)

    harness.equal(scroll_request.class_id, classes.OBJ_SCROLLS)

    local weapon, weapon_site = source_item(
        "nicolae_wu_jian_glorious_leap", "level:-2")
    local expression = weapon:match("=%s*(.+)$")
    local selected = item_specs.parse(expression, weapon_site)[1][1]
    local request = resolve.item({}, selected, 5, weapon_site)

    harness.equal(request.class_id, classes.OBJ_WEAPONS)
    harness.equal(request.quality, quality.STAR)

    local book, book_site = source_item(
        "grunt_temple_overflow_magic_moments", "spells:necrotise")
    local included = item_specs.parse(book, book_site)[1][1]
    local resolved = resolve.item({}, included, 5, book_site)

    harness.equal(resolved.spells[1], "SPELL_NECROTISE")

    local rng = {}

    function rng:random(_, bound)
        return bound - 1
    end

    local rolled = { components = {} }

    random_books.roll(rng, items.get("items", item_ids.BOOK_RANDART_THEME), {
        depth = 5,
        -- Deliberately use another school: a random theme draw cannot
        -- satisfy this assertion by coincidentally choosing Necrotise.
        disc = schools.CONJURATION,
        numspells = resolved.numspells,
        included_spells = resolved.spells,
        owner = resolved.owner,
    }, rolled)

    harness.equal(rolled.components[component.ITEM_RANDOM_BOOK].spells[1],
        "SPELL_NECROTISE", "the authored spell reaches the live book")
end

return test
