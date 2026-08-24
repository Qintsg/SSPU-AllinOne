#!/usr/bin/env python3
"""清源视觉候选完整性校验器测试。"""

from __future__ import annotations

import json
from pathlib import Path
import struct
import tempfile
import unittest
import zlib

from validate_visual_artifacts import VisualArtifactValidationError, validate_visual_artifacts


def _chunk(kind: bytes, payload: bytes) -> bytes:
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload))


def _png(width: int, height: int) -> bytes:
    signature = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    rows = b"".join(b"\x00" + b"\xff\xff\xff" * width for _ in range(height))
    return signature + _chunk(b"IHDR", ihdr) + _chunk(b"IDAT", zlib.compress(rows)) + _chunk(b"IEND", b"")


class VisualArtifactValidatorTest(unittest.TestCase):
    def _fixture(self, root: Path) -> tuple[Path, Path]:
        images = root / "images"
        images.mkdir()
        manifest = root / "manifest.json"
        manifest.write_text(
            json.dumps(
                {
                    "meta": {
                        "platforms": ["windows"],
                        "themes": ["light"],
                        "viewports": [{"width": 4, "height": 3}],
                    },
                    "surfaces": [
                        {
                            "id": "external.pdf",
                            "group": "external",
                            "states": ["loading", "content"],
                            "externalRegions": ["document"],
                            "externalRegionStates": {"document": ["content"]},
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        image = images / "external.pdf--content--light--4x3.png"
        image.write_bytes(_png(4, 3))
        (images / "external.pdf--loading--light--4x3.png").write_bytes(_png(4, 3))
        (images / f"{image.name}.regions.json").write_text(
            json.dumps(
                {
                    "externalRegions": [
                        {"id": "document", "x": 0, "y": 1, "width": 4, "height": 2}
                    ]
                }
            ),
            encoding="utf-8",
        )
        return images, manifest

    def test_complete_inventory_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            images, manifest = self._fixture(Path(temp_dir))
            self.assertEqual(validate_visual_artifacts(images, manifest, "windows"), (2, 1))

    def test_registered_hyphenated_scenario_state_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            images, manifest = self._fixture(Path(temp_dir))
            payload = json.loads(manifest.read_text(encoding="utf-8"))
            payload["meta"]["scenarioStates"] = ["operation-locked"]
            payload["surfaces"][0]["states"].append("operation-locked")
            manifest.write_text(json.dumps(payload), encoding="utf-8")
            (images / "external.pdf--operation-locked--light--4x3.png").write_bytes(
                _png(4, 3)
            )

            self.assertEqual(
                validate_visual_artifacts(images, manifest, "windows"),
                (3, 1),
            )

    def test_missing_image_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            images, manifest = self._fixture(Path(temp_dir))
            next(images.glob("*.png")).unlink()
            with self.assertRaisesRegex(VisualArtifactValidationError, "缺少 1 张候选图"):
                validate_visual_artifacts(images, manifest, "windows")

    def test_out_of_bounds_external_region_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            images, manifest = self._fixture(Path(temp_dir))
            sidecar = next(images.glob("*.regions.json"))
            payload = json.loads(sidecar.read_text(encoding="utf-8"))
            payload["externalRegions"][0]["height"] = 4
            sidecar.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(VisualArtifactValidationError, "超出截图边界"):
                validate_visual_artifacts(images, manifest, "windows")

    def test_app_drawn_loading_state_rejects_external_sidecar(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            images, manifest = self._fixture(Path(temp_dir))
            source = next(images.glob("*content*.regions.json"))
            target = images / "external.pdf--loading--light--4x3.png.regions.json"
            target.write_bytes(source.read_bytes())
            with self.assertRaisesRegex(VisualArtifactValidationError, "不应降级阈值"):
                validate_visual_artifacts(images, manifest, "windows")


if __name__ == "__main__":
    unittest.main()
