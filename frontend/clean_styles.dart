import 'dart:io';

void main() {
  final files = [
    'd:/web/IzinFlow/frontend/lib/features/dashboard/presentation/pages/teacher_dashboard.dart',
    'd:/web/IzinFlow/frontend/lib/features/dashboard/presentation/pages/super_admin_dashboard.dart',
    'd:/web/IzinFlow/frontend/lib/features/dashboard/presentation/pages/student_dashboard.dart',
    'd:/web/IzinFlow/frontend/lib/features/dashboard/presentation/pages/org_admin_dashboard.dart',
  ];

  for (final filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) continue;

    var content = file.readAsStringSync();

    content = content.replaceAll(RegExp(r'elevation:\s*\d+,?'), '');
    content = content.replaceAll(RegExp(r'shadowColor:\s*Colors\.[a-zA-Z0-9_]+,?'), '');
    
    // Removing specific border declarations
    content = content.replaceAll(RegExp(r'border:\s*(const\s+)?OutlineInputBorder\([^)]*\)\)\),?'), '');
    content = content.replaceAll(RegExp(r'border:\s*(const\s+)?OutlineInputBorder\([^)]*\)\),?'), '');
    
    // Fallback removing simple ones
    content = content.replaceAll(RegExp(r'border:\s*OutlineInputBorder\(borderRadius:\s*BorderRadius\.circular\(\d+\)\),?'), '');
    
    // shape declarations
    content = content.replaceAll(RegExp(r'shape:\s*(const\s+)?RoundedRectangleBorder\([^)]*\)\),?'), '');
    content = content.replaceAll(RegExp(r'shape:\s*(const\s+)?RoundedRectangleBorder\([\s\S]*?borderRadius:\s*BorderRadius\.circular\(\d+\),?\s*\),?'), '');
    content = content.replaceAll(RegExp(r'shape:\s*(const\s+)?RoundedRectangleBorder\(borderRadius:\s*BorderRadius\.circular\(\d+\)\),?'), '');

    file.writeAsStringSync(content);
  }

  print('Cleaned up hardcoded styles using Dart.');
}
