with open("lib/data/database_helper.dart", "r") as f:
    c = f.read()

c = c.replace("} catch (e) {\n      print('Error seeding database: $e');",
"} catch (e) {\n      // ignore: avoid_print\n      print('Error seeding database: $e');")

with open("lib/data/database_helper.dart", "w") as f:
    f.write(c)

with open("lib/presentation/screens/reports_hub_screen.dart", "r") as f:
    c = f.read()

lines = c.split('\n')
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
c = c.replace("subtitle: Text('Akun: $akunName', style: const TextStyle(color: AppColors.secondaryText)),",
"subtitle: Text('Akun: $akunName', style: const TextStyle(color: AppColors.secondaryText)),")
with open("lib/presentation/screens/reports_hub_screen.dart", "w") as f:
    f.write(c)
