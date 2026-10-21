-- Source Gridlike sometimes fills a room with two nested materials.
-- Each pair keeps the original outer/inner DES glyphs and source weight;
-- gridlike_fills translates keyed glyphs into final terrain and effects.
return {
    {
        outer = "n",
        inner = "L",
        weight = 5,
    },
    {
        outer = "n",
        inner = "y",
        weight = 5,
    },
    {
        outer = "n",
        inner = "z",
        weight = 5,
    },
    {
        outer = "W",
        inner = "z",
        weight = 2,
    },
    {
        outer = "l",
        inner = "L",
        weight = 1,
    },
    {
        outer = "1",
        inner = "z",
        weight = 1,
    },
    {
        outer = "1",
        inner = "y",
        weight = 1,
    },
    {
        outer = "w",
        inner = "t",
        weight = 1,
    },
    {
        outer = "W",
        inner = "t",
        weight = 1,
    },
    {
        outer = "b",
        inner = "b",
        weight = 1,
    },
    {
        outer = "l",
        inner = "b",
        weight = 2,
    },
    {
        outer = "w",
        inner = "b",
        weight = 2,
    },
    {
        outer = "W",
        inner = "b",
        weight = 2,
    },
    {
        outer = "1",
        inner = "t",
        weight = 1,
    },
    {
        outer = "l",
        inner = "v",
        weight = 2,
    },
    {
        outer = "w",
        inner = "v",
        weight = 2,
    },
    {
        outer = "W",
        inner = "v",
        weight = 2,
    },
    {
        outer = "l",
        inner = "c",
        weight = 2,
    },
    {
        outer = "w",
        inner = "c",
        weight = 2,
    },
    {
        outer = "W",
        inner = "c",
        weight = 2,
    },
}
