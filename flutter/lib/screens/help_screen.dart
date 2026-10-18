import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../core/theme.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = <({String question, String answer})>[
    (
      question: 'How do I add a project?',
      answer:
          'Open the Projects tab and tap "New Project". Give it a name, location, budget and dates — you can track progress, tasks, team and materials from the project page.',
    ),
    (
      question: 'How is progress calculated?',
      answer:
          'Progress comes from the tasks you complete on a project, and you can also set it manually from the project page with the quick progress update.',
    ),
    (
      question: 'What happens to my materials stock?',
      answer:
          'Each material has a quantity, unit and stock status. Quantities you edit are saved per project, and low or critical levels are flagged on the Materials tab.',
    ),
    (
      question: 'Is my data private?',
      answer:
          'Your data is stored in your own database and every screen only loads records that belong to your account.',
    ),
    (
      question: 'I forgot my password — what now?',
      answer:
          'Password resets are handled by your workspace administrator, because accounts are created for you. Contact support with your account email.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.md,
            Spacing.xl,
            Spacing.xxxl,
          ),
          children: [
            Row(
              children: [
                IconBadge(
                  icon: Icons.chevron_left,
                  background: Colors.white,
                  tone: AppColors.text,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: Spacing.md),
                const Entrance(
                  child: Text(
                    'Help & Support',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xl),

            Entrance(
              delay: const Duration(milliseconds: 80),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Ionicons.headset_outline,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        const Expanded(
                          child: Text(
                            'Talk to a human',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    const Text(
                      'Our support team replies to every message within one business day.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    const Row(
                      children: [
                        Expanded(
                          child: _ContactChip(
                            icon: Ionicons.mail_outline,
                            label: 'support@buildtrack.app',
                          ),
                        ),
                        SizedBox(width: Spacing.sm),
                        Expanded(
                          child: _ContactChip(
                            icon: Ionicons.call_outline,
                            label: '+1 555 0142',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),

            Entrance(
              delay: const Duration(milliseconds: 140),
              child: const Text(
                'Frequently asked questions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),

            for (var i = 0; i < _faqs.length; i++)
              Entrance(
                delay: Duration(milliseconds: 200 + i * 70),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.md),
                  child: _FaqTile(faq: _faqs[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq});

  final ({String question, String answer}) faq;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(Spacing.md),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: Spacing.sm),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textMuted,
          title: Text(
            faq.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq.answer,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: Spacing.sm),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
