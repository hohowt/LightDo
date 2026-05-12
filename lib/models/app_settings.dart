class AppSettings {
  const AppSettings({
    required this.expandCompletedByDefault,
    required this.confirmBeforeClearingCompleted,
    required this.compactMode,
    required this.alwaysOnTop,
    required this.minimizeToTrayOnClose,
    required this.launchAtStartup,
    required this.enableGlobalHotkey,
    required this.enableNotifications,
    this.syncEnabled = false,
    this.themeMode = 0,
    this.accentColorIndex = 0,
    this.ballSize = 1,
    this.ballOpacity = 1.0,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      expandCompletedByDefault: false,
      confirmBeforeClearingCompleted: true,
      compactMode: false,
      alwaysOnTop: false,
      minimizeToTrayOnClose: true,
      launchAtStartup: false,
      enableGlobalHotkey: true,
      syncEnabled: false,
      enableNotifications: true,
      themeMode: 0,
      accentColorIndex: 0,
      ballSize: 1,
      ballOpacity: 1.0,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AppSettings.defaults();
    }
    return AppSettings(
      expandCompletedByDefault:
          json['expandCompletedByDefault'] as bool? ?? false,
      confirmBeforeClearingCompleted:
          json['confirmBeforeClearingCompleted'] as bool? ?? true,
      compactMode: json['compactMode'] as bool? ?? false,
      alwaysOnTop: json['alwaysOnTop'] as bool? ?? false,
      minimizeToTrayOnClose: json['minimizeToTrayOnClose'] as bool? ?? true,
      launchAtStartup: json['launchAtStartup'] as bool? ?? false,
      enableGlobalHotkey: json['enableGlobalHotkey'] as bool? ?? true,
      syncEnabled: json['syncEnabled'] as bool? ?? false,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      themeMode: json['themeMode'] as int? ?? 0,
      accentColorIndex: json['accentColorIndex'] as int? ?? 0,
      ballSize: json['ballSize'] as int? ?? 1,
      ballOpacity: (json['ballOpacity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  final bool expandCompletedByDefault;
  final bool confirmBeforeClearingCompleted;
  final bool compactMode;
  final bool alwaysOnTop;
  final bool minimizeToTrayOnClose;
  final bool launchAtStartup;
  final bool enableGlobalHotkey;
  final bool syncEnabled;
  final bool enableNotifications;
  final int themeMode;
  final int accentColorIndex;
  final int ballSize;
  final double ballOpacity;

  AppSettings copyWith({
    bool? expandCompletedByDefault,
    bool? confirmBeforeClearingCompleted,
    bool? compactMode,
    bool? alwaysOnTop,
    bool? minimizeToTrayOnClose,
    bool? launchAtStartup,
    bool? enableGlobalHotkey,
    bool? syncEnabled,
    bool? enableNotifications,
    int? themeMode,
    int? accentColorIndex,
    int? ballSize,
    double? ballOpacity,
  }) {
    return AppSettings(
      expandCompletedByDefault:
          expandCompletedByDefault ?? this.expandCompletedByDefault,
      confirmBeforeClearingCompleted:
          confirmBeforeClearingCompleted ?? this.confirmBeforeClearingCompleted,
      compactMode: compactMode ?? this.compactMode,
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      minimizeToTrayOnClose:
          minimizeToTrayOnClose ?? this.minimizeToTrayOnClose,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      enableGlobalHotkey: enableGlobalHotkey ?? this.enableGlobalHotkey,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      themeMode: themeMode ?? this.themeMode,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
      ballSize: ballSize ?? this.ballSize,
      ballOpacity: ballOpacity ?? this.ballOpacity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expandCompletedByDefault': expandCompletedByDefault,
      'confirmBeforeClearingCompleted': confirmBeforeClearingCompleted,
      'compactMode': compactMode,
      'alwaysOnTop': alwaysOnTop,
      'minimizeToTrayOnClose': minimizeToTrayOnClose,
      'launchAtStartup': launchAtStartup,
      'enableGlobalHotkey': enableGlobalHotkey,
      'syncEnabled': syncEnabled,
      'enableNotifications': enableNotifications,
      'themeMode': themeMode,
      'accentColorIndex': accentColorIndex,
      'ballSize': ballSize,
      'ballOpacity': ballOpacity,
    };
  }
}
