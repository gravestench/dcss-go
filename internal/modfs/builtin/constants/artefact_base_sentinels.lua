-- These selectors describe an artefact base choice before an actual item kind has been resolved.

-- Source: crawl-ref/source/art-data.txt and jewellery-type.h.
-- These source selectors are not ordinary inventory item IDs.
local sentinels = {
    DUMMY_UNASSIGNED = "250",
    RANDOM_KIND = "OBJ_RANDOM",
    RANDOM_RING = "RING_FIRST_RING",
}

return sentinels
