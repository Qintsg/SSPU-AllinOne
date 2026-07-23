#!/usr/bin/env python3
"""校验清源视觉候选目录的清单完整性、PNG 尺寸与外部区域。"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import struct


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
FILE_PATTERN = re.compile(
    r"^(?P<surface>.+)--(?P<state>[^-]+)--(?P<theme>light|dark)--"
    r"(?P<width>\d+)x(?P<height>\d+)\.png$"
)


class VisualArtifactValidationError(ValueError):
    """视觉候选目录不满足冻结前完整性契约。"""


def _png_size(path: Path) -> tuple[int, int]:
    header = path.read_bytes()[:24]
    if len(header) < 24 or header[:8] != PNG_SIGNATURE or header[12:16] != b"IHDR":
        raise VisualArtifactValidationError(f"PNG 无效：{path.name}")
    return struct.unpack(">II", header[16:24])


def _expected_files(manifest: dict) -> tuple[set[str], dict[str, set[str]]]:
    meta = manifest["meta"]
    expected: set[str] = set()
    external_ids: dict[str, set[str]] = {}
    for surface in manifest["surfaces"]:
        surface_id = surface["id"]
        external_ids[surface_id] = set(surface.get("externalRegions", []))
        for state in surface["states"]:
            for theme in meta["themes"]:
                for viewport in meta["viewports"]:
                    expected.add(
                        f'{surface_id}--{state}--{theme}--'
                        f'{viewport["width"]}x{viewport["height"]}.png'
                    )
    return expected, external_ids


def validate_visual_artifacts(root: Path, manifest_path: Path, platform: str) -> tuple[int, int]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    platforms = manifest.get("meta", {}).get("platforms", [])
    if platform not in platforms:
        raise VisualArtifactValidationError(f"视觉清单不包含平台 {platform}")
    expected, external_ids = _expected_files(manifest)
    actual_files = sorted(root.glob("*.png"), key=lambda item: item.name)
    actual = {item.name for item in actual_files}
    missing = sorted(expected - actual)
    unexpected = sorted(actual - expected)
    errors: list[str] = []
    if missing:
        errors.append(f"缺少 {len(missing)} 张候选图：{', '.join(missing[:5])}")
    if unexpected:
        errors.append(f"存在 {len(unexpected)} 张清单外候选图：{', '.join(unexpected[:5])}")

    image_sizes: dict[str, tuple[int, int]] = {}
    for image_path in actual_files:
        match = FILE_PATTERN.fullmatch(image_path.name)
        if match is None:
            errors.append(f"候选图文件名无效：{image_path.name}")
            continue
        try:
            actual_size = _png_size(image_path)
        except VisualArtifactValidationError as error:
            errors.append(str(error))
            continue
        declared_size = (int(match["width"]), int(match["height"]))
        image_sizes[image_path.name] = actual_size
        if actual_size != declared_size:
            errors.append(
                f"{image_path.name} 尺寸 {actual_size[0]}x{actual_size[1]} "
                f"与文件名 {declared_size[0]}x{declared_size[1]} 不一致"
            )

    sidecars = sorted(root.glob("*.png.regions.json"), key=lambda item: item.name)
    surfaces_with_sidecars: set[str] = set()
    for sidecar in sidecars:
        image_name = sidecar.name.removesuffix(".regions.json")
        image_path = root / image_name
        match = FILE_PATTERN.fullmatch(image_name)
        if match is None or image_name not in actual:
            errors.append(f"外部区域 sidecar 没有对应候选图：{sidecar.name}")
            continue
        surface = match["surface"]
        allowed_ids = external_ids.get(surface, set())
        try:
            payload = json.loads(sidecar.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            errors.append(f"外部区域 sidecar 无法解析：{sidecar.name}: {error}")
            continue
        regions = payload.get("externalRegions")
        if not isinstance(regions, list) or not regions:
            errors.append(f"外部区域 sidecar 为空：{sidecar.name}")
            continue
        width, height = image_sizes.get(image_name, (0, 0))
        for region in regions:
            if not isinstance(region, dict):
                errors.append(f"外部区域条目必须是对象：{sidecar.name}")
                continue
            region_id = region.get("id")
            values = [region.get(key) for key in ("x", "y", "width", "height")]
            if region_id not in allowed_ids:
                errors.append(f"{sidecar.name} 使用未声明外部区域 {region_id}")
            if any(not isinstance(value, int) for value in values):
                errors.append(f"{sidecar.name} 外部区域坐标必须是整数")
                continue
            x, y, region_width, region_height = values
            if (
                x < 0
                or y < 0
                or region_width <= 0
                or region_height <= 0
                or x + region_width > width
                or y + region_height > height
            ):
                errors.append(f"{sidecar.name} 外部区域 {region_id} 超出截图边界")
        surfaces_with_sidecars.add(surface)

    required_external_surfaces = {surface for surface, ids in external_ids.items() if ids}
    missing_external = sorted(required_external_surfaces - surfaces_with_sidecars)
    if missing_external:
        errors.append(f"声明外部区域但没有任何 sidecar：{', '.join(missing_external)}")
    if errors:
        raise VisualArtifactValidationError("\n".join(errors))
    return len(actual_files), len(sidecars)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--platform", required=True)
    args = parser.parse_args()
    try:
        image_count, sidecar_count = validate_visual_artifacts(
            args.root.resolve(), args.manifest.resolve(), args.platform
        )
    except (OSError, json.JSONDecodeError, VisualArtifactValidationError) as error:
        parser.exit(1, f"Visual artifact validation failed:\n{error}\n")
    print(
        f"Qingyuan visual artifacts valid: platform={args.platform}, "
        f"images={image_count}, external-sidecars={sidecar_count}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
