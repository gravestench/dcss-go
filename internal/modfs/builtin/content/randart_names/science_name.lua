-- _science_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_science_name_",
    entries = {
        {
            weight = 10,
            text = "Analysis",
        },
        {
            weight = 10,
            text = "Articulation",
        },
        {
            weight = 10,
            text = "Calculation",
        },
        {
            weight = 10,
            text = "Circular Logic",
        },
        {
            weight = 10,
            text = "Classification",
        },
        {
            weight = 10,
            text = "Context",
        },
        {
            weight = 10,
            text = "Evolution",
        },
        {
            weight = 10,
            text = "Experimentation",
        },
        {
            weight = 10,
            text = "Focus",
        },
        {
            weight = 10,
            text = "Gravity",
        },
        {
            weight = 10,
            text = "Inference",
        },
        {
            weight = 10,
            text = "Infinity",
        },
        {
            weight = 10,
            text = "Inquiry",
        },
        {
            weight = 10,
            text = "Instinct",
        },
        {
            weight = 10,
            text = "Intuition",
        },
        {
            weight = 10,
            text = "Objectivity",
        },
        {
            weight = 10,
            text = "Patterns",
        },
        {
            weight = 10,
            text = "Quantum Leap",
        },
        {
            weight = 10,
            text = "Reason",
        },
        {
            weight = 10,
            text = "Rotation",
        },
        {
            weight = 10,
            text = "Subjectivity",
        },
        {
            weight = 10,
            text = "Theory",
        },
        {
            weight = 10,
            text = "Unreason",
        },
        {
            weight = 10,
            text = "the Beginning",
        },
        {
            weight = 10,
            text = "the Big Bang",
        },
        {
            weight = 10,
            text = "the Boiling Point",
        },
        {
            weight = 10,
            text = "the End",
        },
        {
            weight = 10,
            text = "the Mind",
        },
        {
            weight = 10,
            text = "the Nexus",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
