-- A DES overlay contributes one arrival path, and mod.read returns its exact source text.

local test = {}

-- Find the one layered DES path and read its exact text, proving the VFS
-- exposes vault source files without silently duplicating or rewriting them.
function test.run()
    local paths = mod.paths("vaults/arrival", ".des")

    local target = "vaults/arrival/test_entry.des"
    local count = 0

    for _, path in ipairs(paths) do
        if path == target then
            count = count + 1
        end
    end

    assert(count == 1)

    local source = mod.read(target)

    assert(source == "NAME: test_entry\nTAGS: arrival\nMAP\n@\nENDMAP\n")
end

return test
