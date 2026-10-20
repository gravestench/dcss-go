-- Serial controllers pass local generation choices to their child hooks.
-- These keys name transient level choices, never process global state.
local settings = {
    AQUARIUM_POOL_SIZE = "aquarium_pool_size",
    OVERFLOW_ALTAR_COUNT = "overflow_altar_count",
}

return settings
