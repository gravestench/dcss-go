local des = require("policy.generation.vaults.des")
local catalog = require("policy.generation.vaults.catalog")
local directives = require("constants.vault_directives")

local test = {}

local function assert_source_order(vault)
    local colour
    local hook
    local mask

    for index, operation in ipairs(vault.operations) do
        if operation.kind == directives.COLOUR then
            colour = index
        elseif operation.kind == directives.HOOK_RUN then
            hook = index
        elseif operation.kind == directives.KMASK then
            mask = index
        end
    end

    assert(colour and hook and mask)
    assert(colour < hook and hook < mask)
end

function test.run()
    local paths = mod.paths("vaults/arrival", ".des")

    assert(#paths == 339)

    for _, path in ipairs(paths) do
        local vault = des.parse(path, mod.read(path))

        assert(vault.id)
        assert(#vault.rows > 0)
        assert(#vault.operations > 0)
    end

    local path = "vaults/arrival/roderic_crop_circles_arrival_small.des"
    local vault = des.parse(path, mod.read(path))

    assert(vault.id == "roderic_crop_circles_arrival_small")
    assert(vault.tags.arrival)
    assert(vault.orientation == "float")
    assert(vault.weight == 10)
    assert(vault.rows[1] == "11111111111111111")
    assert_source_order(vault)

    local selected = catalog.get(vault.id)

    assert(selected.id == vault.id)
    assert(selected.rows[1] == vault.rows[1])

    local spacedMap = table.concat({
        "NAME: spaced",
        "TAGS: arrival",
        "MAP",
        "  @" .. string.rep(" ", 2),
        "ENDMAP",
        "",
    }, "\n")
    local spaced = des.parse("vaults/arrival/spaced.des", spacedMap)

    assert(spaced.rows[1] == "  @  ")
end

return test
