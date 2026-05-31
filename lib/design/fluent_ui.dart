/*
 * Fluent 2 UI 出口 — 页面层统一使用的 Flutter 基础类型与 Fluent 组件
 * @Project : SSPU-AllinOne
 * @File : fluent_ui.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

export 'package:flutter/foundation.dart';
export 'package:flutter/material.dart'
    hide
        AlertDialog,
        Card,
        CircularProgressIndicator,
        DropdownButton,
        FilledButton,
        LinearProgressIndicator,
        OutlinedButton,
        Switch,
        TextButton;

export 'fluent.dart' hide FluentElevation, FluentSpacing;
