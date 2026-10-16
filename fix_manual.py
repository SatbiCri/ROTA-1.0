import re

# 1. database_helper.dart
with open("lib/data/database_helper.dart", "r") as f:
    c = f.read()
c = c.replace("print('Error seeding database: $e');", "// ignore: avoid_print\n      print('Error seeding database: $e');")
with open("lib/data/database_helper.dart", "w") as f:
    f.write(c)

# 2. equation_screen.dart
with open("lib/presentation/screens/equation_screen.dart", "r") as f:
    c = f.read()
c = c.replace(".withOpacity(", ".withValues(alpha: ")
with open("lib/presentation/screens/equation_screen.dart", "w") as f:
    f.write(c)

# 3. reports_hub_screen.dart
with open("lib/presentation/screens/reports_hub_screen.dart", "r") as f:
    c = f.read()
c = c.replace(".withOpacity(", ".withValues(alpha: ")
c = c.replace("subtitle: const Text('Akun: $akunName', style: TextStyle(color: AppColors.secondaryText)),",
              "subtitle: Text('Akun: $akunName', style: const TextStyle(color: AppColors.secondaryText)),")
c = c.replace("ScaffoldMessenger.of(context).showSnackBar(",
              "if (!context.mounted) return;\n                        ScaffoldMessenger.of(context).showSnackBar(")

lines = c.split("\n")
new_lines = []
skip = False
for line in lines:
    if "final akunName = accounts.firstWhere((a) => a.id == mem.akunId, orElse: () => accounts.first).namaAkun;" in line:
        if not skip:
            new_lines.append(line)
            skip = True
    else:
        new_lines.append(line)
c = "\n".join(new_lines)
with open("lib/presentation/screens/reports_hub_screen.dart", "w") as f:
    f.write(c)

# 4. smart_input_screen.dart
with open("lib/presentation/screens/smart_input_screen.dart", "r") as f:
    c = f.read()
c = c.replace(".withOpacity(", ".withValues(alpha: ")
with open("lib/presentation/screens/smart_input_screen.dart", "w") as f:
    f.write(c)
