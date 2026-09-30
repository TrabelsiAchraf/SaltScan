#!/usr/bin/env python3
"""Merge translations into an .xcstrings catalog.

Usage: python3 tools/add_strings.py <catalog.xcstrings> <strings.json>

strings.json maps each key to its translations:
    {"journal.add": {"en": "Add a portion", "fr": "Ajouter une portion", "ar": "أضف حصة"}}

Existing keys are replaced. Keys stay sorted and the file keeps Xcode's
2-space JSON layout, so diffs only show the added strings.
"""
import json
import sys

catalog_path, strings_path = sys.argv[1], sys.argv[2]
with open(catalog_path, encoding="utf-8") as f:
    catalog = json.load(f)
with open(strings_path, encoding="utf-8") as f:
    additions = json.load(f)

for key, values in additions.items():
    catalog["strings"][key] = {
        "extractionState": "manual",
        "localizations": {
            lang: {"stringUnit": {"state": "translated", "value": value}}
            for lang, value in sorted(values.items())
        },
    }

catalog["strings"] = dict(sorted(catalog["strings"].items()))
with open(catalog_path, "w", encoding="utf-8") as f:
    f.write(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n")
