// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:url_launcher/url_launcher.dart';

// // ---- Edit these ----
// const _name = 'Faheem';
// const _tagline = 'AI Engineer · Data Scientist · Developer · Competitor';
// const _bio =
//     'Student at KUET. I built Reel Counter to track and limit doom-scrolling, '
//     'and to see who among friends is the biggest reel watcher.';
// const _email = 'your.email@example.com';
// const _phone = '+880 1XXX-XXXXXX';
// const _github = 'https://github.com/yourname';
// const _linkedin = 'https://www.linkedin.com/in/yourname';

// class AboutPage extends StatelessWidget {
//   const AboutPage({super.key});

//   Future<void> _open(BuildContext context, Uri uri) async {
//     var ok = false;
//     try {
//       ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } catch (_) {}
//     if (!ok && context.mounted) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text("Couldn't open that")));
//     }
//   }

//   void _copy(BuildContext context, String text) {
//     Clipboard.setData(ClipboardData(text: text));
//     ScaffoldMessenger.of(context)
//         .showSnackBar(const SnackBar(content: Text('Copied')));
//   }

//   Widget _tile(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required String value,
//     required Uri uri,
//   }) {
//     return Card(
//       child: ListTile(
//         leading: Icon(icon),
//         title: Text(title),
//         subtitle: Text(value),
//         trailing: const Icon(Icons.open_in_new, size: 18),
//         onTap: () => _open(context, uri),
//         onLongPress: () => _copy(context, value),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final tt = Theme.of(context).textTheme;

//     return Scaffold(
//       appBar: AppBar(title: const Text('About the creator')),
//       body: ListView(
//         padding: const EdgeInsets.all(20),
//         children: [
//           const SizedBox(height: 8),
//           Center(
//             child: Container(
//               padding: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: cs.primary, width: 3),
//               ),
//               child: ClipOval(
//                 child: Image.asset(
//                   'assets/images/creator.jpg',
//                   width: 128,
//                   height: 128,
//                   fit: BoxFit.cover,
//                   errorBuilder: (_, __, ___) => Container(
//                     width: 128,
//                     height: 128,
//                     color: cs.primaryContainer,
//                     child: const Icon(Icons.person, size: 64),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(_name,
//               textAlign: TextAlign.center,
//               style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
//           const SizedBox(height: 4),
//           Text(_tagline,
//               textAlign: TextAlign.center,
//               style: tt.bodyMedium?.copyWith(color: cs.primary)),
//           const SizedBox(height: 16),
//           Text(_bio, textAlign: TextAlign.center, style: tt.bodyMedium),
//           const SizedBox(height: 24),
//           _tile(
//             context,
//             icon: Icons.email_outlined,
//             title: 'Email',
//             value: _email,
//             uri: Uri(scheme: 'mailto', path: _email),
//           ),
//           _tile(
//             context,
//             icon: Icons.phone_outlined,
//             title: 'Phone',
//             value: _phone,
//             uri: Uri(scheme: 'tel', path: _phone.replaceAll(' ', '')),
//           ),
//           _tile(
//             context,
//             icon: Icons.code,
//             title: 'GitHub',
//             value: _github.replaceFirst('https://', ''),
//             uri: Uri.parse(_github),
//           ),
//           _tile(
//             context,
//             icon: Icons.work_outline,
//             title: 'LinkedIn',
//             value: _linkedin.replaceFirst('https://', ''),
//             uri: Uri.parse(_linkedin),
//           ),
//           const SizedBox(height: 12),
//           Text('Tap to open, long-press to copy.',
//               textAlign: TextAlign.center, style: tt.bodySmall),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---- Edit these ----
const _name = 'Faheem';
const _tagline = 'AI Engineer · Data Scientist · Developer · Competitor';
const _bio =
    'Student at KUET. I built Reel Counter to track and limit doom-scrolling, '
    'and to see who among friends is the biggest reel watcher.';
const _email = 'fayazfaheem01@gmail.com';
const _github = 'github.com/Faheem299';
const _linkedin = 'linkedin.com/in/yourname';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  void _copy(BuildContext context, String label, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label copied')));
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
        trailing: const Icon(Icons.copy, size: 18),
        onTap: () => _copy(context, title, value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About the creator')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary, width: 3),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/creator.png',
                  width: 128,
                  height: 128,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 128,
                    height: 128,
                    color: cs.primaryContainer,
                    child: const Icon(Icons.person, size: 64),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_name,
              textAlign: TextAlign.center,
              style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_tagline,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.primary)),
          const SizedBox(height: 16),
          Text(_bio, textAlign: TextAlign.center, style: tt.bodyMedium),
          const SizedBox(height: 24),
          _tile(context,
              icon: Icons.email_outlined, title: 'Email', value: _email),
          _tile(context, icon: Icons.code, title: 'GitHub', value: _github),
          _tile(context,
              icon: Icons.work_outline, title: 'LinkedIn', value: _linkedin),
          const SizedBox(height: 12),
          Text('Tap a row to copy it.',
              textAlign: TextAlign.center, style: tt.bodySmall),
        ],
      ),
    );
  }
}