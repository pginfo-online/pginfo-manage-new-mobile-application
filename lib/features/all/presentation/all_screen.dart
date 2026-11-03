import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/common.dart';

class AllScreen extends StatefulWidget {
  const AllScreen({super.key});
  @override
  State<AllScreen> createState() => _AllState();
}

class _AllState extends State<AllScreen> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final actions = <(String, IconData, String)>[
      ('Add tenant', Icons.person_add, '/tenants/new'),
      ('Send announcement', Icons.campaign_outlined, '/action/announcements'),
      ('Collect payment', Icons.payments_outlined, '/action/collect'),
      ('Add due', Icons.note_add_outlined, '/action/due'),
      ('Add expense', Icons.receipt_long, '/action/expense'),
      ('Add room', Icons.bed_outlined, '/rooms/new'),
      ('Add property', Icons.apartment, '/properties/new'),
      ('Add lead', Icons.person_search, '/action/lead'),
      ('Complaints', Icons.report_problem_outlined, '/action/complaints'),
      ('Team', Icons.groups_outlined, '/action/team'),
      ('Reports', Icons.analytics_outlined, '/action/report'),
    ];
    return Scaffold(
      appBar: const PgHeader(title: 'All shortcuts'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SearchField(
            hint: 'Search shortcuts',
            onChanged: (v) => setState(() => search = v),
          ),
          const SizedBox(height: 20),
          for (final action in actions.where(
            (a) => a.$1.toLowerCase().contains(search.toLowerCase()),
          ))
            PgCard(
              onTap: () => context.push(action.$3),
              child: Row(
                children: [
                  CircleAvatar(child: Icon(action.$2)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(action.$1)),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
