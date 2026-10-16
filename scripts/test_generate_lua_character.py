"""Checks for the deliberate Lua character catalog refresh tool."""

import unittest

from generate_lua_character import (
    merge_job_grants,
    merge_presentation,
    module_text,
)


class MergeJobGrantsTest(unittest.TestCase):
    def setUp(self):
        self.jobs = {
            "source_revision": "pinned",
            "jobs": [
                {
                    "id": "JOB_ACTIVE",
                    "selectable": True,
                },
                {
                    "id": "JOB_LEGACY",
                    "selectable": False,
                },
                {
                    "id": "JOB_DYNAMIC",
                    "selectable": True,
                },
            ],
        }
        self.gear = {
            "source_revision": "pinned",
            "jobs": [
                {
                    "job_id": "JOB_ACTIVE",
                    "grants": [
                        {
                            "raw": "robe",
                            "kind_id": "ARM_ROBE",
                            "quantity": 1,
                        },
                    ],
                },
                {
                    "job_id": "JOB_DYNAMIC",
                    "grants": None,
                },
            ],
        }

    def test_merges_active_grants_without_offline_description(self):
        rows = merge_job_grants(self.jobs, self.gear)

        self.assertEqual(
            rows[0]["starting_grants"],
            [{"kind_id": "ARM_ROBE", "quantity": 1}],
        )
        self.assertEqual(rows[1]["starting_grants"], [])
        self.assertIsNone(rows[2]["starting_grants"])
        self.assertNotIn("starting_grants", self.jobs["jobs"][0])

    def test_rejects_missing_active_job(self):
        self.gear["jobs"].clear()

        with self.assertRaisesRegex(ValueError, "JOB_ACTIVE"):
            merge_job_grants(self.jobs, self.gear)

    def test_rejects_duplicate_and_unknown_gear_jobs(self):
        self.gear["jobs"].append(self.gear["jobs"][0])

        with self.assertRaisesRegex(ValueError, "duplicate.*JOB_ACTIVE"):
            merge_job_grants(self.jobs, self.gear)

        self.gear["jobs"] = [
            {
                "job_id": "JOB_UNKNOWN",
                "grants": [],
            },
        ]

        with self.assertRaisesRegex(ValueError, "JOB_UNKNOWN"):
            merge_job_grants(self.jobs, self.gear)

    def test_rejects_revision_mismatch(self):
        self.gear["source_revision"] = "different"

        with self.assertRaisesRegex(ValueError, "revision"):
            merge_job_grants(self.jobs, self.gear)

    def test_job_module_imports_item_ids_for_grants(self):
        row = merge_job_grants(self.jobs, self.gear)[0]
        row["source_path"] = "job-data.h"
        text = module_text("jobs", "pinned", row)

        self.assertIn('local item_ids = require("ids.items")', text)
        self.assertIn("kind_id = item_ids.ARM_ROBE", text)
        self.assertNotIn('kind_id = "ARM_ROBE"', text)


class MergePresentationTest(unittest.TestCase):
    def setUp(self):
        self.artifact = {
            "source_revision": "pinned",
            "species": [
                {
                    "id": "SP_TEST",
                    "source_path": "species/test.yaml",
                    "selectable": True,
                    "difficulty": "Simple",
                    "difficulty_priority": 100,
                },
            ],
        }
        self.presentation = {
            "source_revision": "pinned",
            "species_groups": [
                {
                    "label": "Simple",
                    "ids": ["SP_TEST"],
                },
            ],
            "species_descriptions": {
                "SP_TEST": "A source-backed test species.",
            },
        }

    def test_species_description_is_owned_by_definition(self):
        rows = merge_presentation("species", self.artifact,
                                  self.presentation)
        output = module_text("species", "pinned", rows[0])

        self.assertIn('local groups = require("constants.menu_groups")', output)
        self.assertIn("difficulty = groups.SPECIES_SIMPLE", output)
        self.assertIn("description = \"A source-backed test species.\"", output)
        self.assertIn("-- Source: crawl-ref/source/dat/descript/species.txt", output)

    def test_missing_and_duplicate_source_ids_fail(self):
        self.presentation["species_groups"][0]["ids"] = [
            "SP_TEST", "SP_TEST",
        ]

        with self.assertRaisesRegex(ValueError, "duplicate.*SP_TEST"):
            merge_presentation("species", self.artifact,
                               self.presentation)

        self.presentation["species_groups"][0]["ids"] = []

        with self.assertRaisesRegex(ValueError, "missing.*SP_TEST"):
            merge_presentation("species", self.artifact,
                               self.presentation)

    def test_revision_mismatch_fails(self):
        self.presentation["source_revision"] = "different"

        with self.assertRaisesRegex(ValueError, "revision"):
            merge_presentation("species", self.artifact,
                               self.presentation)


if __name__ == "__main__":
    unittest.main()
