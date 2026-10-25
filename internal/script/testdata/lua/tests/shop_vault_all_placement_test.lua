local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local effects = require("constants.vault_effects")
local shop_spec = require("policy.generation.vaults.shop_spec")
local stock_request = require("policy.shops.stock_request")
local quality = require("constants.vault_item_quality")

local test = {}

-- A full open grid gives every standalone shop map enough room; the seeded
-- builder still checks source fit and protected-cell rules.
local function open_builder(ctx)
    local builder = grid.new(ctx)
    local draw = 0

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    -- Cycle deterministic draws across each bound so placing the full vault
    -- catalog can explore candidate cells without relying on a fixed seed.
    function builder:roll(bound)
        draw = draw + 1

        return draw % bound
    end

    return builder
end

-- Parse and place every committed shop vault; checking materialized records
-- catches directives that parse successfully but lose stock during placement.
function test.run(ctx)
    local placed_count = 0
    local stock_errors = {}

    -- Parse and place every committed shop DES file, then inspect each
    -- materialized record instead of relying on parse success alone.
    for _, path in ipairs(mod.paths("vaults/shop", ".des")) do
        local id = path:match("/([^/]+)%.des$")
        local vault = catalog.get(id)

        -- The dead-tree helper has only tree cells. Its parent embeds it;
        -- it is not a standalone secondary vault.
        if #vault.rows > 0 and not vault.tags.nico_deadtrees then
            local builder = open_builder(ctx)
            local placed, reason = extra.place(nil, builder, vault, {
                protected = {},
                required = {},
                player = {
                    branch_id = branches.BRANCH_DUNGEON,
                    depth = 15,
                    absolute_depth = 15,
                    branch_bottom = 15,
                    map_tag = vault.tags.shop and "shop" or nil,
                },
            })

            harness.truthy(placed,
                "shop vault " .. id .. " did not fit: " .. tostring(reason))
            harness.equal(placed.id, id, "source shop map ID")

            for _, record in ipairs(placed.records) do
                if record.kind == effects.FEATURE and
                    shop_spec.is_shop(record.identity) then
                    local site = {
                        path = path,
                        vault_id = id,
                        line = record.line,
                    }

                    for _, alternative in ipairs(
                        shop_spec.parse(record.identity, site)) do
                        for _, selected in ipairs(alternative.items) do
                            local ok, message = pcall(stock_request.apply,
                                {}, {
                                depth = 15,
                                quality = quality.ORDINARY,
                                site = path,
                            }, selected, site)

                            if not ok then
                                stock_errors[#stock_errors + 1] =
                                    tostring(message)
                            end
                        end
                    end
                end
            end

            placed_count = placed_count + 1
        end
    end

    harness.equal(placed_count, 68, "all standalone shop maps fit")
    harness.equal(#stock_errors, 0,
        table.concat(stock_errors, "\n"))
end

return test
