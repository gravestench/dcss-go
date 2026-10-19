-- Source: mon-util.cc:max_corpse_chunks maps the imported monster body size.
local chunks_by_size = {
    SIZE_TINY = 1,
    SIZE_LITTLE = 2,
    SIZE_SMALL = 3,
    SIZE_MEDIUM = 4,
    SIZE_LARGE = 9,
    SIZE_GIANT = 12,
}

local chunks = {}

-- Example: chunks.maximum(definition) with unknown size ID -> 0 body mass
-- Derive body mass from the monster's catalog size for knockback and corpse handling.
function chunks.maximum(definition)
    return chunks_by_size[definition.size_id] or 0
end

return chunks
