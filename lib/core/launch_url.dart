import 'package:url_launcher/url_launcher.dart';

Future<void> launchExternalUrl(String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) throw Exception('Could not open: $url');
}
