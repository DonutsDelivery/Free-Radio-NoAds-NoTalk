#!/usr/bin/env python3
"""Generate Android's narrow HTTP exception list from the canonical catalog."""

from __future__ import annotations

import argparse
import ipaddress
import json
from pathlib import Path
from urllib.parse import urlsplit
from xml.etree import ElementTree as ET


def cleartext_hosts(catalogs: list[Path]) -> list[str]:
    hosts: set[str] = set()
    for catalog in catalogs:
        data = json.loads(catalog.read_text(encoding="utf-8"))
        for key, categories in data.items():
            if not key.endswith("Categories") or not isinstance(categories, list):
                continue
            for category in categories:
                for station in category.get("stations", []):
                    origin = station.get("host", "")
                    parsed = urlsplit(origin)
                    if parsed.scheme == "http" and parsed.hostname:
                        hosts.add(parsed.hostname.lower().rstrip("."))
    return sorted(hosts, key=lambda host: (not _is_ip(host), host))


def _is_ip(host: str) -> bool:
    try:
        ipaddress.ip_address(host)
        return True
    except ValueError:
        return False


def write_policy(catalogs: list[Path], output: Path) -> int:
    hosts = cleartext_hosts(catalogs)
    if not hosts:
        raise RuntimeError("canonical catalog contains no cleartext stream hosts")

    root = ET.Element("network-security-config")
    base = ET.SubElement(root, "base-config", {"cleartextTrafficPermitted": "false"})
    anchors = ET.SubElement(base, "trust-anchors")
    ET.SubElement(anchors, "certificates", {"src": "system"})
    exceptions = ET.SubElement(
        root, "domain-config", {"cleartextTrafficPermitted": "true"}
    )
    for host in hosts:
        domain = ET.SubElement(exceptions, "domain", {"includeSubdomains": "false"})
        domain.text = host

    ET.indent(root, space="    ")
    output.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(root).write(output, encoding="utf-8", xml_declaration=True)
    return len(hosts)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("catalog", nargs="+", type=Path)
    args = parser.parse_args()
    count = write_policy(args.catalog, args.output)
    print(f"Generated {args.output} with {count} exact cleartext hosts")


if __name__ == "__main__":
    main()
