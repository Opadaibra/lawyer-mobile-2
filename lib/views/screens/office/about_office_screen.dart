import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class AboutOfficeScreen extends StatelessWidget {
  const AboutOfficeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'about_office'.tr,
        showNotification: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.primary,
                child: Icon(Icons.business_center, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'app_name'.tr,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'about_the_office_content'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            _buildInfoCard(
              icon: Icons.verified_user_outlined,
              title: 'الاحترافية',
              subtitle: 'نلتزم بأعلى معايير الدقة والاحترافية في متابعة قضاياكم.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.access_time,
              title: 'السرعة والدقة',
              subtitle: 'نقدر وقت موكلينا ونسعى دائماً للإنجاز في أسرع وقت ممكن.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.security,
              title: 'الخصوصية',
              subtitle: 'أسرار موكلينا في أمان تام، ونحافظ على أعلى درجات السرية.',
            ),
            const SizedBox(height: 40),
            Text(
              'تواصل معنا عبر القنوات الرسمية المتوفرة في معلومات المكتب.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
