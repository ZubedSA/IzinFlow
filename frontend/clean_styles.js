const fs = require('fs');

const files = [
  'd:/web/IzinFlow/frontend/lib/features/dashboard/presentation/pages/teacher_dashboard.dart',
  'd:/web/IzinFlow/frontend/lib/features/dashboard/presentation/pages/super_admin_dashboard.dart',
  'd:/web/IzinFlow/frontend/lib/features/dashboard/presentation/pages/student_dashboard.dart',
  'd:/web/IzinFlow/frontend/lib/features/dashboard/presentation/pages/org_admin_dashboard.dart',
];

for (const file of files) {
  let content = fs.readFileSync(file, 'utf8');
  
  // elevation: 2, or elevation: 4,
  content = content.replace(/elevation:\s*\d+,?/g, '');
  
  // shadowColor: Colors.black12,
  content = content.replace(/shadowColor:\s*Colors\.[a-zA-Z0-9_]+,?/g, '');

  // border: OutlineInputBorder(...)
  content = content.replace(/border:\s*(const\s+)?OutlineInputBorder\([^)]*\)\)\),?/g, '');
  content = content.replace(/border:\s*(const\s+)?OutlineInputBorder\([^)]*\)\),?/g, '');

  // shape: RoundedRectangleBorder(...)
  content = content.replace(/shape:\s*(const\s+)?RoundedRectangleBorder\([^)]*\)\),?/g, '');
  content = content.replace(/shape:\s*(const\s+)?RoundedRectangleBorder\([\s\S]*?borderRadius:\s*BorderRadius\.circular\(\d+\),?\s*\),?/g, '');

  fs.writeFileSync(file, content);
}

console.log('Cleaned up hardcoded styles successfully.');
