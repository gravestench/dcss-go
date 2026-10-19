-- _place_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_place_name_",
    entries = {
        {
            weight = 10,
            text = "Beyond",
        },
        {
            weight = 10,
            text = "Distant Shores",
        },
        {
            weight = 10,
            text = "Distant Worlds",
        },
        {
            weight = 10,
            text = "Parts Unknown",
        },
        {
            weight = 10,
            text = "Proximity",
        },
        {
            weight = 10,
            text = "Somewhere Else",
        },
        {
            weight = 10,
            text = "the Blessed Realm",
        },
        {
            weight = 10,
            text = "the Desert",
        },
        {
            weight = 10,
            text = "the Equator",
        },
        {
            weight = 10,
            text = "the Eternal Void",
        },
        {
            weight = 10,
            text = "the Forest",
        },
        {
            weight = 10,
            text = "the Hidden Vale",
        },
        {
            weight = 10,
            text = "the Hills",
        },
        {
            weight = 10,
            text = "the Known World",
        },
        {
            weight = 10,
            text = "the Land of Plenty",
        },
        {
            weight = 10,
            text = "the Maze",
        },
        {
            weight = 10,
            text = "the New World",
        },
        {
            weight = 10,
            text = "the Old World",
        },
        {
            weight = 10,
            text = "the Other Side",
        },
        {
            weight = 10,
            text = "the Pit",
        },
        {
            weight = 10,
            text = "the Poles",
        },
        {
            weight = 10,
            text = "the Sea",
        },
        {
            weight = 10,
            text = "the Shore",
        },
        {
            weight = 10,
            text = "the Spheres",
        },
        {
            weight = 10,
            text = "the Trees",
        },
        {
            weight = 10,
            text = "the Tundras",
        },
        {
            weight = 10,
            text = "the Unseen Realm",
        },
        {
            weight = 10,
            text = "the Valley",
        },
        {
            weight = 10,
            text = "the Valley of Death",
        },
        {
            weight = 10,
            text = "the Volcano",
        },
        {
            weight = 10,
            text = "the Wasteland",
        },
        {
            weight = 10,
            text = "the Wilderness",
        },
        {
            weight = 10,
            text = "the World",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
