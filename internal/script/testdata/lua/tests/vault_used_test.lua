-- Saved map IDs must reproduce source map uniqueness on later floors.
local catalog = require("policy.generation.vaults.catalog")
local ids = require("ids.vaults")
local used = require("policy.generation.vaults.used")
local harness = require("tests.harness")

local test = {}

-- An ordinary map name is used for the whole run. An allow_dup map can
-- recur, but a source luniq name cannot recur on the same floor.
local function name_scopes()
    local state = used.new({
        ids.minmay_shop_grove,
        ids.shop,
        ids.serial_shops,
    })

    harness.falsy(state:allows(catalog.get(ids.minmay_shop_grove)),
        "ordinary map name stays used across floors")
    harness.truthy(state:allows(catalog.get(ids.shop)),
        "allow_dup shop can recur on a later floor")
    harness.truthy(state:allows(catalog.get(ids.serial_shops)),
        "allow_dup luniq controller can recur on a later floor")

    state:add(catalog.get(ids.serial_shops))

    harness.falsy(state:allows(catalog.get(ids.serial_shops)),
        "luniq controller cannot repeat on one floor")
    harness.equal(state:ids()[1], ids.serial_shops,
        "empty-map controller keeps its placed ID")
end

-- Maps with the same luniq_* tag exclude one another on one level, but
-- that local group must not poison later levels of the same run.
local function local_tag_scope()
    local state = used.new({ ids.minmay_shop_grove })

    harness.truthy(state:allows(catalog.get(ids.minmay_shop_star)),
        "local group remains available on a later floor")

    state:add(catalog.get(ids.minmay_shop_star))

    harness.falsy(state:allows(catalog.get(ids.minmay_shoptagon)),
        "another floating shop shares the used local tag")
    harness.equal(state:ids()[1], ids.minmay_shop_star,
        "only this floor's placement enters its ID list")
end

-- A map's uniq_* tag is a run-wide group even if it uses allow_dup.
-- This case uses real source tag data from the arrival catalog.
local function global_tag_scope()
    local state = used.new({
        ids.spicycebolla_arrival_ecumenical,
    })
    local ecumenical = catalog.get(ids.spicycebolla_arrival_ecumenical)

    harness.falsy(state:allows(ecumenical),
        "run-wide altar tag is remembered after the floor changes")

    local tagged_shop = {
        id = ids.shop,
        tags = {
            allow_dup = true,
        },
    }

    -- Give a different, normally duplicable map the source tag. This
    -- isolates tag exclusion from the arrival's own unique name.
    for tag in pairs(ecumenical.tags) do
        if tag:sub(1, 5) == "uniq_" then
            tagged_shop.tags[tag] = true
        end
    end

    harness.falsy(state:allows(tagged_shop),
        "run-wide tag blocks another map even with allow_dup")
end

-- Keep the name and tag checks together so a save can reconstruct both
-- forms of uniqueness from the same committed catalog IDs.
function test.run()
    name_scopes()
    local_tag_scope()
    global_tag_scope()
end

return test
