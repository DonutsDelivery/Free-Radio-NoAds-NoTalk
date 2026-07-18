#!/usr/bin/env python3
"""Generate, validate, and drift-check the Free Radio station catalog."""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CATALOG = ROOT / "freeradio" / "catalog" / "radiodata.json"
DEFAULT_SCHEMA = ROOT / "freeradio" / "catalog" / "radiodata.schema.json"
DEFAULT_OUTPUT = ROOT / "freeradio" / "contents" / "ui" / "radiodata.js"

SCHEMA_REFERENCE = "radiodata.schema.json"
CATALOG_VERSION = 1
CLEAN_HOST_PATTERN = r"^https?://[^/]+$"
PATH_PATTERN = r"^(?!/).*"

CATEGORY_VARIABLES = (
    "somafmCategories",
    "radcapCategories",
    "radioParadiseCategories",
    "fipCategories",
    "miscCategories",
)
EXPORTED_VARIABLES = CATEGORY_VARIABLES + ("miscGenreGroups",)
TOP_LEVEL_REQUIRED = (
    "$schema",
    "catalogVersion",
    *EXPORTED_VARIABLES,
    "allowedDuplicateStreams",
)
STATION_REQUIRED = ("name", "host", "path")
STATION_OPTIONAL = ("description",)
PROVIDER_HOSTS = {
    "somafmCategories": {"https://somafm.com"},
    "radcapCategories": {
        "http://79.111.14.76",
        "http://79.111.119.111",
        "http://79.120.12.130",
        "http://79.120.39.202",
        "http://79.120.77.11",
        "http://213.141.131.10",
    },
    "radioParadiseCategories": {"https://stream.radioparadise.com"},
    "fipCategories": {"https://icecast.radiofrance.fr"},
}


class CatalogError(ValueError):
    """The catalog or a generated compatibility file is invalid."""


def _object_without_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise CatalogError(f"duplicate JSON object key: {key!r}")
        result[key] = value
    return result


def load_catalog(path: Path = DEFAULT_CATALOG) -> dict[str, Any]:
    try:
        with path.open(encoding="utf-8") as handle:
            value = json.load(handle, object_pairs_hook=_object_without_duplicate_keys)
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise CatalogError(f"cannot read {path}: {error}") from error
    if not isinstance(value, dict):
        raise CatalogError("catalog root must be an object")
    return value


def _require_exact_keys(value: dict[str, Any], required: Iterable[str], optional: Iterable[str], context: str) -> None:
    required_keys = set(required)
    keys = set(value)
    missing = required_keys - keys
    unexpected = keys - required_keys - set(optional)
    if missing:
        raise CatalogError(f"{context} is missing keys: {', '.join(sorted(missing))}")
    if unexpected:
        raise CatalogError(f"{context} has unexpected keys: {', '.join(sorted(unexpected))}")


def _require_nonempty_string(value: Any, context: str) -> str:
    if not isinstance(value, str) or not value:
        raise CatalogError(f"{context} must be a non-empty string")
    return value


def _validate_host(host: Any, context: str) -> str:
    host = _require_nonempty_string(host, context)
    parsed = urlparse(host)
    if (
        parsed.scheme not in {"http", "https"}
        or not parsed.netloc
        or parsed.path
        or parsed.params
        or parsed.query
        or parsed.fragment
        or host.endswith("/")
    ):
        raise CatalogError(f"{context} must be a clean HTTP(S) origin without a trailing slash")
    return host


def _station_locations(catalog: dict[str, Any]) -> Iterable[tuple[str, str, dict[str, Any]]]:
    for variable in CATEGORY_VARIABLES:
        for category in catalog[variable]:
            for station in category["stations"]:
                yield variable, category["name"], station


def _stream_locations(catalog: dict[str, Any]) -> dict[tuple[str, str], list[str]]:
    streams: dict[tuple[str, str], list[str]] = defaultdict(list)
    for variable, category_name, station in _station_locations(catalog):
        streams[(station["host"], station["path"])].append(
            f"{variable}/{category_name}/{station['name']}"
        )
    return dict(streams)


def validate_catalog(catalog: dict[str, Any]) -> dict[str, Any]:
    """Validate schema and catalog-specific reference/duplicate constraints."""
    _require_exact_keys(catalog, TOP_LEVEL_REQUIRED, (), "catalog")
    if catalog["$schema"] != SCHEMA_REFERENCE:
        raise CatalogError(f"$schema must be {SCHEMA_REFERENCE!r}")
    if type(catalog["catalogVersion"]) is not int or catalog["catalogVersion"] != CATALOG_VERSION:
        raise CatalogError(f"catalogVersion must be the integer {CATALOG_VERSION}")

    category_count = 0
    station_count = 0
    for variable in CATEGORY_VARIABLES:
        categories = catalog[variable]
        if not isinstance(categories, list) or not categories:
            raise CatalogError(f"{variable} must be a non-empty array")
        if variable in {"radioParadiseCategories", "fipCategories"} and len(categories) != 1:
            raise CatalogError(f"{variable} must contain exactly one QML-reachable category")
        category_names: set[str] = set()
        for category_index, category in enumerate(categories):
            context = f"{variable}[{category_index}]"
            if not isinstance(category, dict):
                raise CatalogError(f"{context} must be an object")
            _require_exact_keys(category, ("name", "stations"), (), context)
            category_name = _require_nonempty_string(category["name"], f"{context}.name")
            if category_name in category_names:
                raise CatalogError(f"duplicate category name in {variable}: {category_name!r}")
            category_names.add(category_name)
            stations = category["stations"]
            if not isinstance(stations, list) or not stations:
                raise CatalogError(f"{context}.stations must be a non-empty array")
            for station_index, station in enumerate(stations):
                station_context = f"{context}.stations[{station_index}]"
                if not isinstance(station, dict):
                    raise CatalogError(f"{station_context} must be an object")
                _require_exact_keys(station, STATION_REQUIRED, STATION_OPTIONAL, station_context)
                _require_nonempty_string(station["name"], f"{station_context}.name")
                host = _validate_host(station["host"], f"{station_context}.host")
                path = station["path"]
                if not isinstance(path, str) or path.startswith("/"):
                    raise CatalogError(f"{station_context}.path must be a string without a leading slash")
                if variable != "miscCategories" and not path:
                    raise CatalogError(f"{station_context}.path must be non-empty for dedicated providers")
                expected_hosts = PROVIDER_HOSTS.get(variable)
                if expected_hosts is not None and host not in expected_hosts:
                    raise CatalogError(f"{station_context}.host is not valid for {variable}")
                if "description" in station:
                    _require_nonempty_string(station["description"], f"{station_context}.description")
                station_count += 1
            category_count += 1

    groups = catalog["miscGenreGroups"]
    if not isinstance(groups, list) or not groups:
        raise CatalogError("miscGenreGroups must be a non-empty array")
    misc_names = {category["name"] for category in catalog["miscCategories"]}
    group_names: set[str] = set()
    referenced: set[str] = set()
    for group_index, group in enumerate(groups):
        context = f"miscGenreGroups[{group_index}]"
        if not isinstance(group, dict):
            raise CatalogError(f"{context} must be an object")
        _require_exact_keys(group, ("name", "categories"), (), context)
        name = _require_nonempty_string(group["name"], f"{context}.name")
        if name in group_names:
            raise CatalogError(f"duplicate misc genre group name: {name!r}")
        group_names.add(name)
        references = group["categories"]
        if not isinstance(references, list) or not references:
            raise CatalogError(f"{context}.categories must be a non-empty array")
        for reference in references:
            _require_nonempty_string(reference, f"{context}.categories entry")
            if reference not in misc_names:
                raise CatalogError(f"{context} references unknown misc category: {reference!r}")
            if reference in referenced:
                raise CatalogError(f"misc category is referenced by multiple genre groups: {reference!r}")
            referenced.add(reference)
    missing_references = misc_names - referenced
    if missing_references:
        raise CatalogError(
            f"misc categories missing from miscGenreGroups: {', '.join(sorted(missing_references))}"
        )

    streams = _stream_locations(catalog)
    duplicates = {key: locations for key, locations in streams.items() if len(locations) > 1}
    allowlist = catalog["allowedDuplicateStreams"]
    if not isinstance(allowlist, list):
        raise CatalogError("allowedDuplicateStreams must be an array")
    allowed: dict[tuple[str, str], dict[str, Any]] = {}
    for index, entry in enumerate(allowlist):
        context = f"allowedDuplicateStreams[{index}]"
        if not isinstance(entry, dict):
            raise CatalogError(f"{context} must be an object")
        _require_exact_keys(entry, ("host", "path", "reason", "occurrences"), (), context)
        host = _validate_host(entry["host"], f"{context}.host")
        path = entry["path"]
        if not isinstance(path, str) or path.startswith("/"):
            raise CatalogError(f"{context}.path must be a string without a leading slash")
        _require_nonempty_string(entry["reason"], f"{context}.reason")
        occurrences = entry["occurrences"]
        if not isinstance(occurrences, list) or len(occurrences) < 2:
            raise CatalogError(f"{context}.occurrences must list at least two exact locations")
        for occurrence in occurrences:
            _require_nonempty_string(occurrence, f"{context}.occurrences entry")
        if len(occurrences) != len(set(occurrences)):
            raise CatalogError(f"{context}.occurrences contains duplicate locations")
        key = (host, path)
        if key in allowed:
            raise CatalogError(f"duplicate allowlist entry for {host}/{path}")
        allowed[key] = entry

    unapproved = duplicates.keys() - allowed.keys()
    stale = allowed.keys() - duplicates.keys()
    if unapproved:
        details = ", ".join(f"{host}/{path}" for host, path in sorted(unapproved))
        raise CatalogError(f"duplicate streams require explicit allowlist entries: {details}")
    if stale:
        details = ", ".join(f"{host}/{path}" for host, path in sorted(stale))
        raise CatalogError(f"stale duplicate allowlist entries: {details}")
    for key, locations in duplicates.items():
        if allowed[key]["occurrences"] != locations:
            host, path = key
            raise CatalogError(f"duplicate occurrence drift for {host}/{path}")

    return {
        "categories": category_count,
        "stations": station_count,
        "miscGenreGroups": len(groups),
        "duplicates": duplicates,
        "allowedDuplicates": allowed,
    }


def _station_schema(*, hosts: set[str] | None = None, allow_empty_path: bool = False) -> dict[str, Any]:
    host_schema: dict[str, Any] = {"type": "string", "pattern": CLEAN_HOST_PATTERN}
    if hosts is not None:
        host_schema = {"enum": sorted(hosts)}
    path_schema: dict[str, Any] = {"type": "string", "pattern": PATH_PATTERN}
    if not allow_empty_path:
        path_schema["minLength"] = 1
    return {
        "type": "object",
        "additionalProperties": False,
        "required": list(STATION_REQUIRED),
        "properties": {
            "name": {"type": "string", "minLength": 1},
            "host": host_schema,
            "path": path_schema,
            "description": {"type": "string", "minLength": 1},
        },
    }


def schema_document() -> dict[str, Any]:
    """Build the JSON Schema from the same constants used by validation."""
    properties: dict[str, Any] = {
        "$schema": {"const": SCHEMA_REFERENCE},
        "catalogVersion": {"type": "integer", "const": CATALOG_VERSION},
    }
    for variable in CATEGORY_VARIABLES:
        category_schema: dict[str, Any] = {
            "type": "array",
            "minItems": 1,
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["name", "stations"],
                "properties": {
                    "name": {"type": "string", "minLength": 1},
                    "stations": {
                        "type": "array",
                        "minItems": 1,
                        "items": _station_schema(
                            hosts=PROVIDER_HOSTS.get(variable),
                            allow_empty_path=variable == "miscCategories",
                        ),
                    },
                },
            },
        }
        if variable in {"radioParadiseCategories", "fipCategories"}:
            category_schema["maxItems"] = 1
        properties[variable] = category_schema
    properties["miscGenreGroups"] = {
        "type": "array",
        "minItems": 1,
        "items": {
            "type": "object",
            "additionalProperties": False,
            "required": ["name", "categories"],
            "properties": {
                "name": {"type": "string", "minLength": 1},
                "categories": {
                    "type": "array",
                    "minItems": 1,
                    "items": {"type": "string", "minLength": 1},
                },
            },
        },
    }
    properties["allowedDuplicateStreams"] = {
        "type": "array",
        "items": {
            "type": "object",
            "additionalProperties": False,
            "required": ["host", "path", "reason", "occurrences"],
            "properties": {
                "host": {"type": "string", "pattern": CLEAN_HOST_PATTERN},
                "path": {"type": "string", "pattern": PATH_PATTERN},
                "reason": {"type": "string", "minLength": 1},
                "occurrences": {
                    "type": "array",
                    "minItems": 2,
                    "uniqueItems": True,
                    "items": {"type": "string", "minLength": 1},
                },
            },
        },
    }
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "radiodata.schema.json",
        "title": "Free Radio ordered station catalog",
        "type": "object",
        "additionalProperties": False,
        "required": list(TOP_LEVEL_REQUIRED),
        "properties": properties,
    }


def render_schema() -> str:
    return json.dumps(schema_document(), ensure_ascii=False, indent=2) + "\n"


def render_javascript(catalog: dict[str, Any], *, already_validated: bool = False) -> str:
    if not already_validated:
        validate_catalog(catalog)
    lines = [
        ".pragma library",
        "",
        "// GENERATED FILE. DO NOT EDIT.",
        "// Edit freeradio/catalog/radiodata.json and run:",
        "//   python3 tools/radiodata_catalog.py generate",
        "",
    ]
    for variable in EXPORTED_VARIABLES:
        encoded = json.dumps(catalog[variable], ensure_ascii=False, separators=(",", ":"))
        lines.append(f"var {variable} = {encoded}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def _write_if_changed(path: Path, content: str) -> bool:
    try:
        if path.exists() and path.read_text(encoding="utf-8") == content:
            return False
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise CatalogError(f"cannot write {path}: {error}") from error
    return True


def _print_report(report: dict[str, Any]) -> None:
    print(
        f"valid catalog: {report['categories']} categories, "
        f"{report['stations']} stations, {report['miscGenreGroups']} misc genre groups"
    )
    print(f"allowed duplicate streams: {len(report['duplicates'])}")
    for key, locations in report["duplicates"].items():
        host, path = key
        reason = report["allowedDuplicates"][key]["reason"]
        print(f"  {host}/{path} ({len(locations)} exact occurrences): {reason}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    generate_parser = subparsers.add_parser("generate", help="generate schema and QML compatibility output")
    generate_parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    generate_parser.add_argument("--schema", type=Path, default=DEFAULT_SCHEMA)
    generate_parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)

    validate_parser = subparsers.add_parser("validate", help="validate the canonical catalog")
    validate_parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)

    check_parser = subparsers.add_parser("check", help="validate and check all generated-file drift")
    check_parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    check_parser.add_argument("--schema", type=Path, default=DEFAULT_SCHEMA)
    check_parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)

    args = parser.parse_args(argv)
    try:
        catalog = load_catalog(args.catalog)
        if args.command == "validate":
            _print_report(validate_catalog(catalog))
        elif args.command == "generate":
            report = validate_catalog(catalog)
            js_changed = _write_if_changed(
                args.output, render_javascript(catalog, already_validated=True)
            )
            schema_changed = _write_if_changed(args.schema, render_schema())
            print(f"generated {args.output}" if js_changed else f"unchanged {args.output}")
            print(f"generated {args.schema}" if schema_changed else f"unchanged {args.schema}")
            _print_report(report)
        elif args.command == "check":
            report = validate_catalog(catalog)
            expected_files = {
                args.output: render_javascript(catalog, already_validated=True),
                args.schema: render_schema(),
            }
            for path, expected in expected_files.items():
                try:
                    actual = path.read_text(encoding="utf-8")
                except (OSError, UnicodeError) as error:
                    raise CatalogError(f"cannot read generated output {path}: {error}") from error
                if actual != expected:
                    raise CatalogError(
                        f"generated-file drift in {path}; run python3 tools/radiodata_catalog.py generate"
                    )
            _print_report(report)
            print("generated catalog files are current")
    except CatalogError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
