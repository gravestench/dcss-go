-- summoning is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "summoning",
    entries = {
        {
            weight = 10,
            text = "Accompaniment",
        },
        {
            weight = 10,
            text = "Accomplices",
        },
        {
            weight = 10,
            text = "Adjuration",
        },
        {
            weight = 10,
            text = "Allies",
        },
        {
            weight = 10,
            text = "Apparitions",
        },
        {
            weight = 10,
            text = "Assembling",
        },
        {
            weight = 10,
            text = "Attendants",
        },
        {
            weight = 10,
            text = "Beckoning",
        },
        {
            weight = 10,
            text = "Calling",
        },
        {
            weight = 10,
            text = "Command",
        },
        {
            weight = 10,
            text = "Companions",
        },
        {
            weight = 10,
            text = "Convocation",
        },
        {
            weight = 10,
            text = "Creation",
        },
        {
            weight = 10,
            text = "Formation",
        },
        {
            weight = 10,
            text = "Generation",
        },
        {
            weight = 10,
            text = "Illusion",
        },
        {
            weight = 10,
            text = "Invitation",
        },
        {
            weight = 10,
            text = "Leadership",
        },
        {
            weight = 10,
            text = "Mustering",
        },
        {
            weight = 10,
            text = "Production",
        },
        {
            weight = 10,
            text = "Rallying",
        },
        {
            weight = 1,
            text = "Sidekicks",
        },
        {
            weight = 10,
            text = "Summoning",
        },
        {
            weight = 10,
            text = "the Comitatus",
        },
        {
            weight = 10,
            text = "the Commander",
        },
        {
            weight = 10,
            text = "the Congregation",
        },
        {
            weight = 10,
            text = "the Entourage",
        },
        {
            weight = 10,
            text = "the Escort",
        },
        {
            weight = 10,
            text = "the Flock",
        },
        {
            weight = 10,
            text = "the Gathering",
        },
        {
            weight = 10,
            text = "the Legion",
        },
        {
            weight = 10,
            text = "the Retinue",
        },
        {
            weight = 10,
            text = "the Swarm",
        },
        {
            weight = 10,
            text = "the Throng",
        },
        {
            weight = 10,
            text = "the Union",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
