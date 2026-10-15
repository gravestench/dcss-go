-- Source: body-size.h:body_size_type. Ordered for size comparisons.
local size = {
    TINY = "SIZE_TINY",
    LITTLE = "SIZE_LITTLE",
    SMALL = "SIZE_SMALL",
    MEDIUM = "SIZE_MEDIUM",
    LARGE = "SIZE_LARGE",
    GIANT = "SIZE_GIANT",
}

size.rank = {
    [size.TINY] = 0,
    [size.LITTLE] = 1,
    [size.SMALL] = 2,
    [size.MEDIUM] = 3,
    [size.LARGE] = 4,
    [size.GIANT] = 5,
}

return size
