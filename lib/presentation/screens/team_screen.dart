import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/member_model.dart';
import '../../logic/providers/member_provider.dart';
import '../../logic/money.dart';
import '../widgets/form_utils.dart';
import 'home_screen.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final members = ref.watch(memberListProvider);
    final memberNotifier = ref.read(memberListProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Text(
          'Mon équipe',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 4),
        Text('${members.length} membres · suivi partagé du budget'),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.groups_rounded, color: colorScheme.onPrimary),
              const SizedBox(height: 22),
              Text(
                'Dépenses de l’équipe',
                style: TextStyle(
                  color: colorScheme.onPrimary.withValues(alpha: 0.78),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatMoney(memberNotifier.teamTotal, currency.code),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Période en cours · Budget partagé',
                style: TextStyle(
                  color: colorScheme.onPrimary.withValues(alpha: 0.72),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Membres',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
            TextButton.icon(
              onPressed: () => _showInviteSheet(context, ref),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Inviter'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (members.isEmpty)
          _EmptyMembers(onInvite: () => _showInviteSheet(context, ref))
        else
          ...members.map((member) => _MemberTile(
                id: member.id,
                name: member.name,
                role: member.role.label,
                currencyCode: currency.code,
                spent: memberNotifier.spentByMember(member.id),
                onTap: () => _showRoleSheet(context, ref, member),
                onDelete: () async {
                  await memberNotifier.deleteMember(member.id);
                  if (!context.mounted) return;
                  showUndoSnackBar(
                    context,
                    message: '${member.name} retiré de l’équipe',
                    onUndo: () => memberNotifier.updateMember(member),
                  );
                },
              )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showInviteSheet(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un membre à l’équipe'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        if (memberNotifier.settlements.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Remboursements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                for (final t in memberNotifier.settlements)
                  ListTile(
                    leading:
                        Icon(Icons.swap_horiz, color: colorScheme.primary),
                    title: Text(
                        '${_nameOf(members, t.fromId)} doit '
                        '${formatMoney(t.amount, currency.code)} '
                        'à ${_nameOf(members, t.toId)}'),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        Text('Accès et rôles',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                leading:
                    Icon(Icons.shield_outlined, color: colorScheme.primary),
                title: const Text('Administrateurs'),
                subtitle: const Text('Gèrent les budgets et les membres'),
                trailing: Text('${memberNotifier.countByRole(MemberRole.admin)}'),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              ListTile(
                leading:
                    Icon(Icons.person_outline, color: colorScheme.secondary),
                title: const Text('Membres actifs'),
                subtitle: const Text('Peuvent ajouter leurs dépenses'),
                trailing: Text('${memberNotifier.countByRole(MemberRole.member)}'),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              ListTile(
                leading: Icon(Icons.visibility_outlined,
                    color: colorScheme.tertiary),
                title: const Text('Lecteurs'),
                subtitle: const Text('Consultation en lecture seule'),
                trailing: Text('${memberNotifier.countByRole(MemberRole.viewer)}'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _nameOf(List<MemberModel> members, String id) =>
      members.firstWhere((m) => m.id == id).name;

  Future<void> _showRoleSheet(
    BuildContext context,
    WidgetRef ref,
    MemberModel member,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Rôle de ${member.name}',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final role in MemberRole.values)
              ListTile(
                title: Text(role.label),
                trailing: role == member.role ? const Icon(Icons.check) : null,
                onTap: () async {
                  await ref
                      .read(memberListProvider.notifier)
                      .updateMember(member.copyWith(role: role));
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInviteSheet(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    var role = MemberRole.member;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Wrap(
            runSpacing: 14,
            children: [
              Text('Inviter un membre',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom du membre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              DropdownButtonFormField<MemberRole>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Rôle'),
                items: MemberRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (value) => setState(() => role = value!),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  await ref
                      .read(memberListProvider.notifier)
                      .addMember(name: name, role: role);
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.send_outlined),
                label: const Text('Ajouter à l’équipe'),
              ),
            ],
          ),
        ),
      ),
    );
    nameController.dispose();
  }
}

class _MemberTile extends StatelessWidget {
  final String id;
  final String name;
  final String role;
  final String currencyCode;
  final double spent;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _MemberTile({
    required this.id,
    required this.name,
    required this.role,
    required this.currencyCode,
    required this.spent,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
        name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();
    return Dismissible(
      key: ValueKey(id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Icon(Icons.delete_outline),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      child: Card(
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: Text(initials,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          title:
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(role),
          trailing: Text(formatMoney(spent, currencyCode),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
        ),
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  final VoidCallback onInvite;

  const _EmptyMembers({required this.onInvite});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          child: Column(
            children: [
              Icon(Icons.groups_outlined,
                  size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              const Text('Aucun membre enregistré.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onInvite,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Inviter un membre'),
              ),
            ],
          ),
        ),
      );
}
