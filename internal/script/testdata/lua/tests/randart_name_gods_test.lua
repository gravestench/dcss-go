local catalog = require("policy.catalog")
local gods = require("constants.gods")
local brands = require("constants.weapon_brands")
local property_ids = require("ids.artefact_properties")
local items = require("ids.items")
local harness = require("tests.harness")
local name_gods = require("policy.item_generation.artefacts.name_gods")

local test = {}

-- A name may invoke a god without being an actual divine gift. The source
-- still rejects gods whose rules conflict with the rolled item's type,
-- brand, base weapon, or properties.
local function incompatible_god_names_are_excluded()
    local dagger = catalog.get("items", items.WPN_DAGGER)
    local robe = catalog.get("items", items.ARM_ROBE)
    local demon_blade = catalog.get("items", items.WPN_DEMON_BLADE)

    harness.falsy(name_gods.eligible(gods.MAKHLEB, dagger,
        brands.HOLY_WRATH, {}), "evil god cannot name a holy weapon")
    harness.falsy(name_gods.eligible(gods.ELYVILON, dagger,
        brands.NORMAL, {}), "peaceful god does not name weapons")
    harness.falsy(name_gods.eligible(gods.TROG, robe,
        brands.NORMAL, {}), "Trog names weapons only")
    harness.falsy(name_gods.eligible(gods.ZIN, dagger,
        brands.NORMAL, { [property_ids.CONTAM] = 1 }),
        "Zin avoids contaminated artefacts")
    harness.falsy(name_gods.eligible(gods.SHINING_ONE, demon_blade,
        brands.HOLY_WRATH, {}),
        "good gods reject demonic weapon bases")
    harness.falsy(name_gods.eligible(gods.DITHMENOS, dagger,
        brands.NORMAL, { [property_ids.STEALTH] = -1 }),
        "Dithmenos avoids stealth penalties")
    harness.falsy(name_gods.eligible(gods.JIYVA, dagger,
        brands.NORMAL, {}), "Jiyva never names an artefact")
    harness.truthy(name_gods.eligible(gods.SHINING_ONE, dagger,
        brands.HOLY_WRATH, {}),
        "Shining One may name a suitable holy weapon")
end

-- Xom's source display name alternates between its short name and a
-- weighted long epithet before being substituted into a database phrase.
local function xom_uses_source_long_names()
    -- Select the long form, then its first and most common source epithet.
    local function first()
        return 0
    end

    -- Select the short form without drawing an epithet at all.
    local function short()
        return 1
    end

    harness.equal(name_gods.xom_name(first), "Xom of Chaos",
        "weighted source long name")
    harness.equal(name_gods.xom_name(short), "Xom",
        "source short name")
end

-- Keep divine name suitability and Xom spelling in one source rule test.
function test.run()
    incompatible_god_names_are_excluded()
    xom_uses_source_long_names()
end

return test
