local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local ammunition = require("ids.ammunition")
local player_brands = require("policy.combat.player_brands")
local brands = require("constants.weapon_brands")
local harness = require("tests.harness")

local test = {}

function test.run()
    local seen = {}
    local count = 0

    for _, definition in ipairs(catalog.all(categories.ITEMS)) do
        local weapon = definition.weapon

        if weapon and weapon.ammo_id == ammunition.NONE and
            type(weapon.brand_weights) == "table" then
            for _, weight in ipairs(weapon.brand_weights) do
                if weight.weight > 0 and not seen[weight.brand_id] then
                    player_brands.check(weight.brand_id)
                    seen[weight.brand_id] = true
                    count = count + 1
                end
            end
        end
    end

    harness.equal(count, 15,
        "all positive-weight generated melee brands load player rules")

    -- Chaos Knight's forced ego has no positive generation weight.
    player_brands.check(brands.CHAOS)
end

return test
