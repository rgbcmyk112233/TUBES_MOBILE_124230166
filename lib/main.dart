import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/time_utils.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TimeUtil.initializeTimezones();

  await NotificationService.instance.initialize();

  await dotenv.load(fileName: "lib/key.env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
