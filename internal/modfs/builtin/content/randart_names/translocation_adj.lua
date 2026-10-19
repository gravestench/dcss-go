-- translocation adj is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "translocation adj",
    entries = {
        {
            weight = 1,
            text = "Akashic",
        },
        {
            weight = 10,
            text = "Dimensional",
        },
        {
            weight = 10,
            text = "Discontinuous",
        },
        {
            weight = 10,
            text = "Dislocated",
        },
        {
            weight = 10,
            text = "Displaced",
        },
        {
            weight = 10,
            text = "Distorted",
        },
        {
            weight = 10,
            text = "Elliptic",
        },
        {
            weight = 10,
            text = "Geometric",
        },
        {
            weight = 10,
            text = "Hyperbolic",
        },
        {
            weight = 10,
            text = "Non-Euclidean",
        },
        {
            weight = 10,
            text = "Planar",
        },
        {
            weight = 10,
            text = "Quantum",
        },
        {
            weight = 10,
            text = "Shifting",
        },
        {
            weight = 10,
            text = "Spatial",
        },
        {
            weight = 10,
            text = "Topological",
        },
        {
            weight = 10,
            text = "Translocated",
        },
        {
            weight = 10,
            text = "Transposed",
        },
        {
            weight = 10,
            text = "Twisted",
        },
        {
            weight = 10,
            text = "Unstable",
        },
        {
            weight = 10,
            text = "Warped",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
