import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Payment',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Telephony telephony = Telephony.instance;
  String status = "Stopped";
  int smsCount = 0;
  
  final String API_URL = "https://your-server.com/api/sms.php";
  final String SECRET_KEY = "your_secret_key";

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    await Permission.sms.request();
    await Permission.phone.request();
  }

  void startListening() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        String body = message.body ?? "";
        if (isPaymentSms(body)) {
          sendToServer(body, message.address ?? "");
        }
        setState(() {
          smsCount++;
        });
      },
      listenInBackground: false,
    );
    
    setState(() {
      status = "Running";
    });
  }

  bool isPaymentSms(String sms) {
    List<String> keywords = ['bkash', 'nagad', 'rocket', 'cash in', 'received'];
    return keywords.any((k) => sms.toLowerCase().contains(k));
  }

  Future<void> sendToServer(String smsBody, String sender) async {
    try {
      var response = await http.post(
        Uri.parse(API_URL),
        body: {
          'secret_key': SECRET_KEY,
          'sms_body': smsBody,
          'sender': sender,
        },
      );
      
      if (response.statusCode == 200) {
        print("SMS sent successfully");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMS Payment Auto Verify')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $status', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text('SMS Received: $smsCount', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: startListening,
              child: const Text('Start SMS Service'),
            ),
          ],
        ),
      ),
    );
  }
}