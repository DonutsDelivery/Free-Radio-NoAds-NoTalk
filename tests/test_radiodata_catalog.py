import copy
import json
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
from pathlib import Path
from unittest import mock

from tools import radiodata_catalog


def generated_export(source: str, variable: str):
    prefix = f"var {variable} = "
    line = next(line for line in source.splitlines() if line.startswith(prefix))
    return json.loads(line[len(prefix) :])


class CatalogValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = radiodata_catalog.load_catalog()

    # AC: @single-source-radio-catalog ac-3
    def test_schema_is_generated_from_shared_constraints(self):
        actual = radiodata_catalog.DEFAULT_SCHEMA.read_text(encoding="utf-8")
        self.assertEqual(actual, radiodata_catalog.render_schema())
        schema = json.loads(actual)
        self.assertEqual(schema["required"], list(radiodata_catalog.TOP_LEVEL_REQUIRED))
        duplicate_host = schema["properties"]["allowedDuplicateStreams"]["items"]["properties"]["host"]
        self.assertEqual(duplicate_host["pattern"], radiodata_catalog.CLEAN_HOST_PATTERN)
        self.assertEqual(duplicate_host["format"], "uri")
        self.assertEqual(schema["properties"]["radioParadiseCategories"]["maxItems"], 1)
        self.assertEqual(schema["properties"]["fipCategories"]["maxItems"], 1)

    # AC: @single-source-radio-catalog ac-3
    def test_schema_like_field_and_provider_constraints(self):
        mutations = {
            "boolean version": lambda c: c.__setitem__("catalogVersion", True),
            "unknown station field": lambda c: c["somafmCategories"][0]["stations"][0].__setitem__("extra", True),
            "wrong provider host": lambda c: c["somafmCategories"][0]["stations"][0].__setitem__("host", "https://example.com"),
            "empty provider path": lambda c: c["fipCategories"][0]["stations"][0].__setitem__("path", ""),
            "trailing host slash": lambda c: c["miscCategories"][0]["stations"][0].__setitem__("host", "https://example.com/"),
            "leading path slash": lambda c: c["miscCategories"][0]["stations"][0].__setitem__("path", "/stream"),
            "unreachable FIP category": lambda c: c["fipCategories"].append(copy.deepcopy(c["fipCategories"][0])),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                catalog = copy.deepcopy(self.catalog)
                mutate(catalog)
                with self.assertRaises(radiodata_catalog.CatalogError):
                    radiodata_catalog.validate_catalog(catalog)

    # AC: @single-source-radio-catalog ac-3
    def test_malformed_origins_fail_cleanly_and_match_schema_pattern(self):
        malformed_origins = (
            "https://user:secret@example.com",
            "https://example.com/",
            "https://example.com:0",
            "https://example.com:65536",
            "https://example.com:abc",
            "https://example.com ",
            "https://example.com\n",
            "https://[::1",
            "https://[:::1]",
            "https://999.1.1.1",
            "https://example%20.com",
        )
        schema = radiodata_catalog.schema_document()
        pattern = schema["properties"]["miscCategories"]["items"]["properties"]["stations"]["items"]["properties"]["host"]["pattern"]
        self.assertEqual(pattern, radiodata_catalog.CLEAN_HOST_PATTERN)
        for origin in malformed_origins:
            with self.subTest(origin=repr(origin)):
                catalog = copy.deepcopy(self.catalog)
                catalog["miscCategories"][0]["stations"][0]["host"] = origin
                with self.assertRaises(radiodata_catalog.CatalogError):
                    radiodata_catalog.validate_catalog(catalog)

    # AC: @single-source-radio-catalog ac-3
    def test_paths_reject_control_characters(self):
        for path in ("stream\nname", "stream\x00name", "stream\x85name"):
            with self.subTest(path=repr(path)):
                catalog = copy.deepcopy(self.catalog)
                catalog["miscCategories"][0]["stations"][0]["path"] = path
                with self.assertRaisesRegex(radiodata_catalog.CatalogError, "control characters"):
                    radiodata_catalog.validate_catalog(catalog)

    # AC: @single-source-radio-catalog ac-3
    def test_misc_group_references_are_complete_and_unique(self):
        report = radiodata_catalog.validate_catalog(self.catalog)
        self.assertGreater(report["categories"], 0)
        self.assertGreater(report["stations"], 0)
        misc_names = {category["name"] for category in self.catalog["miscCategories"]}
        references = [
            category_name
            for group in self.catalog["miscGenreGroups"]
            for category_name in group["categories"]
        ]
        self.assertEqual(set(references), misc_names)
        self.assertEqual(len(references), len(set(references)))

        catalog = copy.deepcopy(self.catalog)
        catalog["miscGenreGroups"][0]["categories"][0] = "not a category"
        with self.assertRaisesRegex(radiodata_catalog.CatalogError, "unknown misc category"):
            radiodata_catalog.validate_catalog(catalog)

    # AC: @single-source-radio-catalog ac-3
    def test_duplicate_policy_pins_exact_reviewed_occurrences(self):
        report = radiodata_catalog.validate_catalog(self.catalog)
        self.assertTrue(report["duplicates"])
        for key, locations in report["duplicates"].items():
            self.assertEqual(report["allowedDuplicates"][key]["occurrences"], locations)

        catalog = copy.deepcopy(self.catalog)
        catalog["allowedDuplicateStreams"][0]["occurrences"].reverse()
        with self.assertRaisesRegex(radiodata_catalog.CatalogError, "occurrence drift"):
            radiodata_catalog.validate_catalog(catalog)

        catalog = copy.deepcopy(self.catalog)
        station = catalog["somafmCategories"][0]["stations"][1]
        existing = catalog["somafmCategories"][0]["stations"][0]
        station["host"] = existing["host"]
        station["path"] = existing["path"]
        with self.assertRaisesRegex(radiodata_catalog.CatalogError, "explicit allowlist"):
            radiodata_catalog.validate_catalog(catalog)

    # AC: @single-source-radio-catalog ac-3
    def test_invalid_utf8_is_a_clean_catalog_error(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "catalog.json"
            path.write_bytes(b"\xff")
            with self.assertRaises(radiodata_catalog.CatalogError):
                radiodata_catalog.load_catalog(path)


class GenerationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = radiodata_catalog.load_catalog()
        cls.generated = radiodata_catalog.render_javascript(cls.catalog)

    # AC: @single-source-radio-catalog ac-1
    def test_generated_output_is_deterministic_and_has_no_drift(self):
        self.assertEqual(self.generated, radiodata_catalog.render_javascript(self.catalog))
        self.assertEqual(
            self.generated,
            radiodata_catalog.DEFAULT_OUTPUT.read_text(encoding="utf-8"),
        )

    # AC: @single-source-radio-catalog ac-1
    def test_all_exports_round_trip_with_exact_order_and_values(self):
        for variable in radiodata_catalog.EXPORTED_VARIABLES:
            self.assertEqual(generated_export(self.generated, variable), self.catalog[variable])

    # AC: @single-source-radio-catalog ac-2
    def test_stable_migration_baseline_detects_identity_rename_reorder_or_removal(self):
        baseline = json.loads(
            radiodata_catalog.DEFAULT_BASELINE.read_text(encoding="utf-8")
        )
        self.assertEqual(baseline, radiodata_catalog.migration_baseline(self.catalog))
        self.assertEqual(baseline["favoriteIdentity"], ["name", "host", "path"])

        mutations = {
            "rename": lambda c: c["somafmCategories"][0]["stations"][0].__setitem__("name", "Renamed"),
            "reorder": lambda c: c["somafmCategories"][0]["stations"].reverse(),
            "removal": lambda c: c["somafmCategories"][0]["stations"].pop(),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                changed = copy.deepcopy(self.catalog)
                mutate(changed)
                self.assertNotEqual(
                    radiodata_catalog.migration_baseline(changed), baseline
                )

    # AC: @single-source-radio-catalog ac-1
    def test_unchanged_generation_preserves_mtime(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "radiodata.js"
            self.assertTrue(radiodata_catalog._write_if_changed(path, self.generated))
            before = path.stat().st_mtime_ns
            self.assertFalse(radiodata_catalog._write_if_changed(path, self.generated))
            self.assertEqual(path.stat().st_mtime_ns, before)

    # AC: @single-source-radio-catalog ac-1
    def test_generated_qml_escapes_javascript_line_separators(self):
        catalog = copy.deepcopy(self.catalog)
        description = f"before{chr(0x2028)}middle{chr(0x2029)}after"
        catalog["somafmCategories"][0]["stations"][0]["description"] = description
        generated = radiodata_catalog.render_javascript(catalog)
        self.assertNotIn(chr(0x2028), generated)
        self.assertNotIn(chr(0x2029), generated)
        self.assertIn("\\u2028", generated)
        self.assertIn("\\u2029", generated)
        self.assertEqual(
            generated_export(generated, "somafmCategories")[0]["stations"][0]["description"],
            description,
        )

    # AC: @single-source-radio-catalog ac-1
    def test_generate_and_check_require_three_distinct_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            shared = Path(directory) / "shared"
            collisions = (
                (radiodata_catalog.DEFAULT_CATALOG, shared, shared),
                (radiodata_catalog.DEFAULT_CATALOG, radiodata_catalog.DEFAULT_CATALOG, shared),
            )
            for command in ("generate", "check"):
                for catalog, schema, output in collisions:
                    with self.subTest(command=command, schema=str(schema)), redirect_stdout(StringIO()), redirect_stderr(StringIO()):
                        result = radiodata_catalog.main(
                            [
                                command,
                                "--catalog",
                                str(catalog),
                                "--schema",
                                str(schema),
                                "--output",
                                str(output),
                            ]
                        )
                    self.assertEqual(result, 1)
                    self.assertFalse(shared.exists())

    # AC: @single-source-radio-catalog ac-1
    def test_two_file_generation_rolls_back_if_second_replace_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "radiodata.js"
            schema = Path(directory) / "radiodata.schema.json"
            output.write_text("old js", encoding="utf-8")
            schema.write_text("old schema", encoding="utf-8")
            real_replace = radiodata_catalog.os.replace
            calls = 0

            def fail_second_replace(source, destination):
                nonlocal calls
                calls += 1
                if calls == 2:
                    raise OSError("simulated second replace failure")
                return real_replace(source, destination)

            with mock.patch.object(radiodata_catalog.os, "replace", side_effect=fail_second_replace):
                with self.assertRaisesRegex(radiodata_catalog.CatalogError, "atomically replace"):
                    radiodata_catalog._write_generated_transaction(
                        {output: "new js", schema: "new schema"}
                    )
            self.assertEqual(output.read_text(encoding="utf-8"), "old js")
            self.assertEqual(schema.read_text(encoding="utf-8"), "old schema")

    # AC: @single-source-radio-catalog ac-4
    def test_check_command_rejects_generated_drift(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "radiodata.js"
            output.write_text("stale\n", encoding="utf-8")
            with redirect_stdout(StringIO()), redirect_stderr(StringIO()):
                result = radiodata_catalog.main(
                    [
                        "check",
                        "--catalog",
                        str(radiodata_catalog.DEFAULT_CATALOG),
                        "--schema",
                        str(radiodata_catalog.DEFAULT_SCHEMA),
                        "--output",
                        str(output),
                    ]
                )
            self.assertEqual(result, 1)

    # AC: @single-source-radio-catalog ac-4
    def test_release_workflow_blocks_builds_on_catalog_check(self):
        workflow = (radiodata_catalog.ROOT / ".github" / "workflows" / "build.yml").read_text(encoding="utf-8")
        self.assertIn("python3 tools/radiodata_catalog.py check", workflow)
        self.assertIn("pull_request:", workflow)
        self.assertIn("branches: ['**']", workflow)
        self.assertGreaterEqual(workflow.count("needs: catalog-check"), 4)
        self.assertGreaterEqual(workflow.count("github.event_name == 'workflow_dispatch'"), 4)
        self.assertIn('-x "contents/ui/radiodata_radcap.js"', workflow)


if __name__ == "__main__":
    unittest.main()
