import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/locale_provider.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final List<Category>? allCategories;
  final String type;
  final bool enabled;
  final void Function(Category) onPick;
  const CategoryGrid({
    super.key,
    required this.categories,
    this.allCategories,
    required this.type,
    required this.enabled,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final loc = context.watch<LocaleProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: AppTheme.fgMuted, letterSpacing: 0.8)),
        const Spacer(),
        GestureDetector(
          onTap: () => _manageCategories(context, sp, allCategories ?? categories),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Icon(Icons.more_vert, size: 18, color: AppTheme.fgMuted),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, childAspectRatio: 2.6, mainAxisSpacing: 8, crossAxisSpacing: 8,
        children: categories.where((c) => !sp.catHidden(c.id)).map((c) {
          final t = loc.t('cat_${c.id}');
          final label = sp.catLabel(c.id, c.label, localizedLabel: t.startsWith('cat_') ? null : t);
          final emoji = sp.catEmoji(c.id, c.emoji);
          return GestureDetector(
            onTap: enabled ? () => onPick(c) : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: enabled ? 1 : 0.35,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border, width: 1.5),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  void _manageCategories(BuildContext context, SettingsProvider sp, List<Category> allCategories) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) {
      return Consumer<SettingsProvider>(
        builder: (sheetContext, provider, child) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  const Text('Manage Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _addCategory(context, provider, type);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.amber),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Flexible(child: SingleChildScrollView(child: Column(
                children: allCategories.map((c) {
                  final label = provider.catLabel(c.id, c.label);
                  final emoji = provider.catEmoji(c.id, c.emoji);
                  final hidden = provider.catHidden(c.id);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    leading: Text(emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(label, style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: hidden ? AppTheme.fgMuted : null,
                      decoration: hidden ? TextDecoration.lineThrough : null,
                    )),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (provider.isCustomCat(c.id))
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => provider.deleteCustomCategory(c.id),
                          )
                        else
                          IconButton(
                            icon: Icon(hidden ? Icons.visibility_off : Icons.visibility, color: AppTheme.fgMuted),
                            onPressed: () => provider.setCatHidden(c.id, !hidden),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppTheme.fgMuted),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _editCategory(context, provider, c, label, emoji);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ))),
            ]),
          );
        }
      );
    });
  }

  void _editCategory(BuildContext context, SettingsProvider sp, Category c, String label, String emoji) {
    final labelCtrl = TextEditingController(text: label);
    final emojiCtrl = TextEditingController(text: emoji);
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) {
      return Padding(
        padding: EdgeInsets.fromLTRB(18, 22, 18, MediaQuery.of(context).viewInsets.bottom + 22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Text('Edit Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const Spacer(),
            TextButton(
              onPressed: () { sp.resetCatOverride(c.id); Navigator.pop(context); },
              child: const Text('Reset to Default', style: TextStyle(color: AppTheme.amber, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            SizedBox(
              width: 70,
              child: TextField(controller: emojiCtrl, autofocus: true, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24), decoration: const InputDecoration(labelText: 'Emoji')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Name')),
            ),
          ]),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.amber, foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              sp.setCatOverride(c.id, label: labelCtrl.text.trim(), emoji: emojiCtrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          )),
        ]),
      );
    });
  }

  void _addCategory(BuildContext context, SettingsProvider sp, String type) {
    final labelCtrl = TextEditingController();
    final emojiCtrl = TextEditingController(text: '✨');
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) {
      return Padding(
        padding: EdgeInsets.fromLTRB(18, 22, 18, MediaQuery.of(context).viewInsets.bottom + 22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(alignment: Alignment.centerLeft, child: Text('New Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          const SizedBox(height: 16),
          Row(children: [
            SizedBox(
              width: 70,
              child: TextField(controller: emojiCtrl, autofocus: true, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24), decoration: const InputDecoration(labelText: 'Emoji')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Name')),
            ),
          ]),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.amber, foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              if (labelCtrl.text.trim().isNotEmpty) {
                sp.addCustomCategory(type, label: labelCtrl.text.trim(), emoji: emojiCtrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          )),
        ]),
      );
    });
  }
}
