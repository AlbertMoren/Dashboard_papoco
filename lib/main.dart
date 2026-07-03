import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importando o dotenv
import 'login_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase passando as chaves Web de forma direta e garantida
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBDkVa3u3dt3QFb_gp2BbKr2FuW8ggXRx0",
      authDomain: "matchlist-e26af.firebaseapp.com",
      projectId: "matchlist-e26af",
      storageBucket: "matchlist-e26af.firebasestorage.app",
      messagingSenderId: "371457570557",
      appId: "1:371457570557:web:2c8882c121c374ee89b094",
    ),
  );

  runApp(const PapocoAdminApp());
}

class PapocoAdminApp extends StatelessWidget {
  const PapocoAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Papoco Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0917B3), 
        cardColor: Colors.white, 
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF4B00), 
          secondary: Color(0xFF1424CC), 
        ),
        textTheme: GoogleFonts.robotoTextTheme(), 
      ),
      home: const LoginPage(),
    );
  }
}