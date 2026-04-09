class AppSettings {
  const AppSettings({
    required this.expandCompletedByDefault,
    required this.confirmBeforeClearingCompleted,
    required this.compactMode,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      expandCompletedByDefault: true,
      confirmBeforeClearingCompleted: true,
      compactMode: false,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AppSettings.defaults();
    }
    return AppSettings(
      expandCompletedByDefault: json['expandCompletedByDefault'] as bool? ?? true,
      confirmBeforeClearingCompleted:
          json['confirmBeforeClearingCompleted'] as bool? ?? true,
      compactMode: json['compactMode'] as bool? ?? false,
    );
  }

  final bool expandCompletedByDefault;
  final bool confirmBeforeClearingCompleted;
  final bool compactMode;

  AppSettings copyWith({
    bool? expandCompletedByDefault,
    bool? confirmBeforeClearingCompleted,
    bool? compactMode,
  }) {
    return AppSettings(
      expandCompletedByDefault:
          expandCompletedByDefault ?? this.expandCompletedByDefault,
      confirmBeforeClearingCompleted: confirmBeforeClearingCompleted ??
          this.confirmBeforeClearingCompleted,
      compactMode: compactMode ?? this.compactMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expandCompletedByDefault': expandCompletedByDefault,
      'confirmBeforeClearingCompleted': confirmBeforeClearingCompleted,
      'compactMode': compactMode,
    };
  }
}
