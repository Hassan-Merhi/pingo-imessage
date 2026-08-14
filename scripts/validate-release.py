#!/usr/bin/env python3
from __future__ import annotations

import json
import plistlib
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def read(path: str) -> str:
    target = ROOT / path
    require(target.exists(), f"missing required file: {path}")
    content = target.read_text(encoding="utf-8")
    require(content.strip() != "", f"required file is empty: {path}")
    return content


project = read("ios/project.yml")
require('MARKETING_VERSION: 1.0.0' in project, "Wave 7 must ship MARKETING_VERSION 1.0.0")
require(re.search(r"CURRENT_PROJECT_VERSION:\s*[1-9][0-9]*", project) is not None, "build number must be a positive integer")
require("PRODUCT_BUNDLE_IDENTIFIER: com.pingo.messages\n" in project, "unexpected Messages app bundle identifier")
require("PRODUCT_BUNDLE_IDENTIFIER: com.pingo.messages.extension" in project, "unexpected Messages extension bundle identifier")
require("ITSAppUsesNonExemptEncryption: false" in project, "export-compliance declaration is missing")
require("PingoAPIBaseURL: $(PINGO_API_BASE_URL)" in project, "API URL must be supplied through a build setting")
require("PingoMessageBaseURL: $(PINGO_MESSAGE_BASE_URL)" in project, "message URL must be supplied through a build setting")

manifest_path = ROOT / "ios/Resources/PrivacyInfo.xcprivacy"
with manifest_path.open("rb") as handle:
    privacy = plistlib.load(handle)
require(privacy.get("NSPrivacyTracking") is False, "privacy manifest must explicitly disable tracking")
require(privacy.get("NSPrivacyTrackingDomains") == [], "tracking domains must remain empty")
require(isinstance(privacy.get("NSPrivacyCollectedDataTypes"), list), "privacy data-type declarations are missing")
collected = {entry.get("NSPrivacyCollectedDataType") for entry in privacy["NSPrivacyCollectedDataTypes"]}
expected_collected = {
    "NSPrivacyCollectedDataTypeUserID",
    "NSPrivacyCollectedDataTypeOtherUserContent",
    "NSPrivacyCollectedDataTypeProductInteraction",
}
require(expected_collected.issubset(collected), "privacy manifest no longer describes Pingo's backend data model")
for entry in privacy["NSPrivacyCollectedDataTypes"]:
    require(entry.get("NSPrivacyCollectedDataTypeTracking") is False, "collected data must not be marked as tracking")

source = read("Sources/PingoCore/Progression/PingoSeriesStore.swift")
source_product_ids = set(re.findall(r'case\s+\w+\s*=\s*"(com\.pingo\.[^"]+)"', source))
require(len(source_product_ids) == 7, f"expected 7 StoreKit product IDs in source, found {len(source_product_ids)}")

storekit = json.loads(read("ios/StoreKit/Pingo.storekit"))
products = storekit.get("products", [])
storekit_ids = {product.get("productID") for product in products}
require(storekit_ids == source_product_ids, "local StoreKit catalog must exactly match PingoStoreProduct identifiers")
require(len(products) == len(storekit_ids), "StoreKit catalog contains duplicate product IDs")
require(all(product.get("type") == "NonConsumable" for product in products), "all Pingo unlocks must remain non-consumable")
require(all(product.get("displayPrice") for product in products), "every local StoreKit product needs a test price")
require(all(product.get("localizations") for product in products), "every local StoreKit product needs localization metadata")

metadata = json.loads(read("release/app-store/metadata/en-US.json"))
limits = {
    "subtitle": 30,
    "promotionalText": 170,
    "description": 4000,
    "keywords": 100,
}
for key, limit in limits.items():
    value = metadata.get(key, "")
    require(isinstance(value, str) and value.strip(), f"App Store metadata field is missing: {key}")
    require(len(value) <= limit, f"App Store metadata field {key} exceeds {limit} characters")
require(metadata.get("name") == "Pingo", "release metadata name must match the app display name")
require(metadata.get("primaryCategory") == "Games", "Pingo should remain in the Games category")

catalog = json.loads(read("release/app-store/iap-products.json"))
catalog_ids = {product.get("productID") for product in catalog.get("products", [])}
require(catalog_ids == source_product_ids, "App Store IAP catalog must exactly match source product identifiers")
require(all(product.get("type") == "NON_CONSUMABLE" for product in catalog["products"]), "App Store products must be non-consumable")

required_release_files = [
    "release/app-store/APP-STORE-CHECKLIST.md",
    "release/app-store/PRIVACY-ANSWERS.md",
    "release/app-store/REVIEW-NOTES.md",
    "release/app-store/TESTFLIGHT-NOTES.md",
    "release/app-store/required-values.env.example",
    "docs/PRIVACY.md",
    "docs/SUPPORT.md",
    ".github/workflows/app-store-release.yml",
    "ios/scripts/validate-release-env.sh",
    "ios/scripts/app-store-archive.sh",
]
for path in required_release_files:
    read(path)

try:
    tracked = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True).splitlines()
except (subprocess.CalledProcessError, FileNotFoundError):
    tracked = []
for path in tracked:
    lower = path.lower()
    require(not lower.endswith((".p8", ".p12", ".mobileprovision", ".cer")), f"signing secret must never be committed: {path}")
    require("secrets.xcconfig" not in lower, f"secret Xcode configuration must never be committed: {path}")

print("Wave 7 release readiness validation passed")
print(f"- marketing version: 1.0.0")
print(f"- StoreKit products: {len(source_product_ids)}")
print(f"- privacy data types: {len(collected)}")
print("- tracked signing secrets: none")
