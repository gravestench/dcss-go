-- ashenzari is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "ashenzari",
    entries = {
        {
            weight = 100,
            text = "of the @_ashenzari_adjective_@ @_ashenzari_object_@",
        },
        {
            weight = 100,
            text = "of @god_name@'s @_ashenzari_object_@",
        },
        {
            weight = 100,
            text = "\"@_ashenzari_adjective_@ @_ashenzari_object_@\"",
        },
        {
            weight = 50,
            text = "\"@_ashenzari_object_@ of @god_name@\"",
        },
        {
            weight = 100,
            text = "\"@_ashenzari_object_@ of the @_ashenzari_epithet_@\"",
        },
        {
            weight = 20,
            text = "\"@_celestial_bodies_@ of the @_ashenzari_epithet_@\"",
        },
        {
            weight = 20,
            text = "of the @_ashenzari_epithet_@",
        },
        {
            weight = 20,
            text = "of the @_ashenzari_bound_adjective_@ @_celestial_bodies_@",
        },
        {
            weight = 20,
            text = "of the @_ashenzari_knowledge_adjective_@ @_celestial_bodies_@",
        },
        {
            weight = 20,
            text = "of @god_name@'s @_celestial_bodies_@",
        },
        {
            weight = 20,
            text = "\"Share My @_ashenzari_object_@\"",
        },
        {
            weight = 20,
            text = "\"@_ashenzari_bound_adjective_@ With Me\"",
        },
        {
            weight = 20,
            text = "\"@_ashenzari_bound_adjective_@ Together\"",
        },
        {
            weight = 10,
            text = "of the @_ashenzari_bound_adjective_@ @_ashenzari_heavens_@",
        },
        {
            weight = 10,
            text = "of the @_ashenzari_knowledge_adjective_@ @_ashenzari_heavens_@",
        },
        {
            weight = 10,
            text = "of the Fated @_ashenzari_object_@",
        },
        {
            weight = 5,
            text = "of Apeoromancy",
        },
        {
            weight = 5,
            text = "\"At What Cost Knowledge?\"",
        },
        {
            weight = 5,
            text = "\"Behold Eternity\"",
        },
        {
            weight = 5,
            text = "of Cremastomancy",
        },
        {
            weight = 5,
            text = "of Curses and Power",
        },
        {
            weight = 5,
            text = "of Desmomancy",
        },
        {
            weight = 5,
            text = "of the Eye in the Sky",
        },
        {
            weight = 5,
            text = "\"Gaze Upon Infinity\"",
        },
        {
            weight = 5,
            text = "\"I Knew You'd Do That\"",
        },
        {
            weight = 5,
            text = "\"I Foresaw This\"",
        },
        {
            weight = 5,
            text = "of Ouranomancy",
        },
        {
            weight = 5,
            text = "\"Overhang to Understand\"",
        },
        {
            weight = 5,
            text = "\"Per Aspera Ad Scientiam\"",
        },
        {
            weight = 5,
            text = "of Panopticon",
        },
        {
            weight = 5,
            text = "of Star-Bound Wisdom",
        },
        {
            weight = 5,
            text = "of Supernal Gnosis",
        },
        {
            weight = 5,
            text = "of Supernal Knowledge",
        },
        {
            weight = 5,
            text = "of Supernal Understanding",
        },
        {
            weight = 5,
            text = "of Supernal Wisdom",
        },
        {
            weight = 5,
            text = "\"Thunder Perfect Mind\"",
        },
        {
            weight = 5,
            text = "of Toth-Mos's Legacy",
        },
        {
            weight = 5,
            text = "of the Unyielding Gaze",
        },
        {
            weight = 5,
            text = "of the Wild Blue Yonder",
        },
        {
            weight = 1,
            text = "\"Oscillating Fan\"",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
