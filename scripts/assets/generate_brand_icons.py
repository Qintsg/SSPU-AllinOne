#!/usr/bin/env python
# -*- coding: UTF-8 -*-
'''
品牌图标生成脚本
@Project : SSPU-AllinOne
@File : generate_brand_icons.py
@Author : Qintsg
@Date : 2026-06-07 18:10
'''

from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageOps


PROJECT_ROOT = Path(__file__).resolve().parents[2]
BRAND_DIR = PROJECT_ROOT / 'assets' / 'brand'
APP_ICON_SOURCE = BRAND_DIR / 'app-icon_outer-white-transparent.png'
BADGE_SOURCE = BRAND_DIR / 'badge_outer-white-transparent.png'
BADGE_SVG_SOURCE = BRAND_DIR / 'badge_outer-white-transparent.svg'
APP_ICON_SVG_SOURCE = BRAND_DIR / 'app-icon_outer-white-transparent.svg'

ANDROID_LEGACY_MIPMAP_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}
ANDROID_ADAPTIVE_FOREGROUND_SIZES = {
    'mipmap-mdpi': 108,
    'mipmap-hdpi': 162,
    'mipmap-xhdpi': 216,
    'mipmap-xxhdpi': 324,
    'mipmap-xxxhdpi': 432,
}
WINDOWS_ICO_SIZES = (16, 24, 32, 48, 64, 128, 256)
WEB_ICON_SIZES = {
    'favicon.png': 32,
    'icons/Icon-192.png': 192,
    'icons/Icon-512.png': 512,
    'icons/Icon-maskable-192.png': 192,
    'icons/Icon-maskable-512.png': 512,
}


def _ensure_sources() -> None:
    """
    校验生成所需源文件是否存在。

    :returns: None
    :raises FileNotFoundError: 当任一源图缺失时抛出。
    """
    for source_path in (
        APP_ICON_SOURCE,
        BADGE_SOURCE,
        BADGE_SVG_SOURCE,
        APP_ICON_SVG_SOURCE,
    ):
        if not source_path.exists():
            raise FileNotFoundError(f'缺少品牌源图：{source_path}')


def _open_source(path: Path) -> Image.Image:
    """
    读取源图并归一化为 RGBA 正方形画布。

    :param path: 源图路径。
    :returns: 归一化后的 RGBA 图像。
    """
    with Image.open(path) as image:
        normalized = image.convert('RGBA')
    if normalized.width == normalized.height:
        return normalized

    side = max(normalized.size)
    canvas = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    offset = ((side - normalized.width) // 2, (side - normalized.height) // 2)
    canvas.alpha_composite(normalized, offset)
    return canvas


def _flatten(image: Image.Image, background: tuple[int, int, int]) -> Image.Image:
    """
    将带透明通道的图像平铺到纯色背景上。

    :param image: RGBA 图像。
    :param background: RGB 背景色。
    :returns: RGB 图像。
    """
    canvas = Image.new('RGB', image.size, background)
    canvas.paste(image, mask=image.getchannel('A'))
    return canvas


def _resize(
    image: Image.Image,
    size: int,
    *,
    flatten_background: tuple[int, int, int] | None = None,
) -> Image.Image:
    """
    按正方形尺寸生成缩略图。

    :param image: 源图。
    :param size: 目标边长。
    :param flatten_background: 可选 RGB 背景色，提供时输出 RGB。
    :returns: 缩放后的图像。
    """
    resized = ImageOps.contain(image, (size, size), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    offset = ((size - resized.width) // 2, (size - resized.height) // 2)
    canvas.alpha_composite(resized, offset)
    if flatten_background is None:
        return canvas
    return _flatten(canvas, flatten_background)


def _write_png(
    image: Image.Image,
    target: Path,
    size: int,
    *,
    flatten_background: tuple[int, int, int] | None = None,
) -> None:
    """
    写入指定尺寸 PNG。

    :param image: 源图。
    :param target: 输出路径。
    :param size: 目标边长。
    :param flatten_background: 可选 RGB 背景色，提供时输出无透明图。
    :returns: None
    """
    target.parent.mkdir(parents=True, exist_ok=True)
    _resize(image, size, flatten_background=flatten_background).save(target)


def _write_padded_png(
    image: Image.Image,
    target: Path,
    canvas_size: int,
    content_size: int,
) -> None:
    """
    写入带透明边距的 PNG。

    :param image: 源图。
    :param target: 输出路径。
    :param canvas_size: 目标画布边长。
    :param content_size: 内容安全区边长。
    :returns: None
    """
    target.parent.mkdir(parents=True, exist_ok=True)
    content = _resize(image, content_size)
    canvas = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    offset = ((canvas_size - content_size) // 2, (canvas_size - content_size) // 2)
    canvas.alpha_composite(content, offset)
    canvas.save(target)


def _copy_binary(source: Path, target: Path) -> None:
    """
    复制二进制资产。

    :param source: 源文件。
    :param target: 目标文件。
    :returns: None
    """
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(source.read_bytes())


def _asset_catalog_size(entry: dict[str, str]) -> int:
    """
    从 Apple asset catalog 条目计算实际像素尺寸。

    :param entry: `Contents.json` 中的图像条目。
    :returns: 实际像素边长。
    """
    base_size = float(entry['size'].split('x', maxsplit=1)[0])
    scale = int(entry['scale'].removesuffix('x'))
    return round(base_size * scale)


def _iter_catalog_targets(catalog_path: Path) -> Iterable[tuple[Path, int]]:
    """
    遍历 Apple AppIcon catalog 中需要生成的目标文件。

    :param catalog_path: AppIcon.appiconset 路径。
    :returns: `(目标路径, 目标边长)` 序列。
    """
    contents = json.loads((catalog_path / 'Contents.json').read_text(encoding='utf-8'))
    for entry in contents['images']:
        filename = entry.get('filename')
        if filename:
            yield catalog_path / filename, _asset_catalog_size(entry)


def _write_windows_ico(image: Image.Image, target: Path) -> None:
    """
    写入包含多尺寸位图的 Windows `.ico` 文件。

    :param image: 源图。
    :param target: 输出路径。
    :returns: None
    """
    target.parent.mkdir(parents=True, exist_ok=True)
    base = _resize(image, 256)
    base.save(target, sizes=[(size, size) for size in WINDOWS_ICO_SIZES])


def generate_icons() -> None:
    """
    根据 `assets/brand` 源图生成所有平台图标。

    :returns: None
    """
    _ensure_sources()
    app_icon = _open_source(APP_ICON_SOURCE)
    badge = _open_source(BADGE_SOURCE)

    _copy_binary(BADGE_SVG_SOURCE, PROJECT_ROOT / 'docs' / 'pictures' / 'logo' / 'logo.svg')
    _copy_binary(BADGE_SOURCE, PROJECT_ROOT / 'docs' / 'pictures' / 'logo' / 'logo.png')
    _copy_binary(APP_ICON_SOURCE, PROJECT_ROOT / 'docs' / 'pictures' / 'logo' / 'ico-preview.png')

    _write_png(badge, PROJECT_ROOT / 'assets' / 'images' / 'logo.png', 1024)
    _write_png(app_icon, PROJECT_ROOT / 'assets' / 'images' / 'app_icon.png', 1024)
    _write_windows_ico(app_icon, PROJECT_ROOT / 'assets' / 'images' / 'app_icon.ico')
    _write_windows_ico(
        app_icon,
        PROJECT_ROOT / 'windows' / 'runner' / 'resources' / 'app_icon.ico',
    )

    android_root = PROJECT_ROOT / 'android' / 'app' / 'src' / 'main' / 'res'
    for folder, size in ANDROID_LEGACY_MIPMAP_SIZES.items():
        _write_png(
            app_icon,
            android_root / folder / 'ic_launcher.png',
            size,
            flatten_background=(255, 255, 255),
        )
        _write_png(
            app_icon,
            android_root / folder / 'ic_launcher_round.png',
            size,
            flatten_background=(255, 255, 255),
        )
    for folder, size in ANDROID_ADAPTIVE_FOREGROUND_SIZES.items():
        _write_padded_png(
            app_icon,
            android_root / folder / 'ic_launcher_foreground.png',
            size,
            round(size * 2 / 3),
        )

    for catalog_path in (
        PROJECT_ROOT / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset',
        PROJECT_ROOT / 'macos' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset',
    ):
        for target, size in _iter_catalog_targets(catalog_path):
            _write_png(app_icon, target, size, flatten_background=(255, 255, 255))

    web_root = PROJECT_ROOT / 'web'
    for relative_path, size in WEB_ICON_SIZES.items():
        _write_png(
            app_icon,
            web_root / relative_path,
            size,
            flatten_background=(255, 255, 255),
        )


if __name__ == '__main__':
    generate_icons()
