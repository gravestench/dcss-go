-- DES hooks that call source make_name must use the same Lua name owner as
-- scrolls and Pan lords, while keeping their local layout RNG seed draw.
local catalog = require("policy.generation.vaults.catalog")
local directives = require("constants.vault_directives")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local modes = require("constants.name_modes")
local names = require("policy.names.source")
local operations = require("policy.generation.vaults.operations")

local test = {}

-- The test layout stream returns zero, so the name seed is zero. The
-- alphabet-shop hook changes only the first letter and removes spaces.
function test.run(ctx)
    local vault = catalog.get("nicolae_alphabet_shops")
    local builder = grid.new(ctx)
    local cells = {}

    for row_index, row in ipairs(vault.rows) do
        cells[row_index] = {}

        for column = 1, #row do
            cells[row_index][column] = row:sub(column, column)
        end
    end

    local records = operations.apply(vault, cells, builder, 0, {
        depth = 5,
    })
    local source_name = names.from_seed(ctx, 0, modes.ORDINARY)
        :lower():gsub("%s+", "")

    for _, record in ipairs(records) do
        if record.directive == directives.KFEAT and
            record.identity:find("name:", 1, true) then
            local owner = record.identity:match("name:(%S+)")

            harness.equal(owner:sub(2), source_name:sub(2),
                "vault owner spelling drifted from source make_name")

            return
        end
    end

    error("alphabet shop did not emit its named feature")
end

return test
