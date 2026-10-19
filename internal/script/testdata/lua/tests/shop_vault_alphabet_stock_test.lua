-- Alphabet shop inventory is parsed from the pinned authored stock list.

local content = require(
    "policy.generation.vaults.shop.alphabet_content")
local items = require("policy.generation.vaults.specs.item")
local stock_request = require("policy.shops.stock_request")
local quality = require("constants.vault_item_quality")
local harness = require("tests.harness")

local test = {}

-- Exercise the alphabet shop's authored stock through the parser and builder
-- because its many glyph variants stress source item resolution.
function test.run()
    local errors = {}
    local count = 0
    local site = {
        path = "vaults/shop/nicolae_alphabet_shops.des",
        vault_id = "nicolae_alphabet_shops",
        line = 214,
    }

    for _, list in pairs(content.items) do
        for _, expression in ipairs(list) do
            local selected = items.term(expression, site)
            local ok, message = pcall(stock_request.apply, {}, {
                depth = 15,
                quality = quality.ORDINARY,
                site = site.path,
            }, selected, site)

            if not ok then
                errors[#errors + 1] = tostring(message)
            end

            count = count + 1
        end
    end

    harness.equal(count, 253, "pinned alphabet inventory size")
    harness.equal(#errors, 0, table.concat(errors, "\n"))
end

return test
