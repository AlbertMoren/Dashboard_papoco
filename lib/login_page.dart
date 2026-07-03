import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // <-- MUDANÇA AQUI: Fundo da tela inteira mudado para preto
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, 
            borderRadius: BorderRadius.circular(16), 
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5), // Sombra levemente mais escura para o fundo preto
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- A LOGO DA MARCA ---
              SizedBox(
                height: 100,
                width: 100,
                child: Image.asset(
                  'assets/ORANGE-ICON.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              // -----------------------

              // Título com a fonte oficial FUGAZ ONE
              Text(
                'PAPOCO ADMIN',
                style: GoogleFonts.fugazOne(
                  fontSize: 28,
                  color: Colors.black87,
                  letterSpacing: -1, 
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Painel de Controle',
                style: GoogleFonts.roboto(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'E-mail Administrativo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _senhaController,
                obscureText: true,
                style: const TextStyle(color: Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 52, 
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Botão volta a ser o Laranja Papoco oficial para destacar no container branco e fundo preto
                    backgroundColor: Theme.of(context).colorScheme.primary, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (_emailController.text.isEmpty || _senhaController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preencha e-mail e senha!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    try {
                      // 1. Tenta autenticar a senha
                      UserCredential credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: _emailController.text.trim(),
                        password: _senhaController.text.trim(),
                      );

                      // 2. Vai no banco de dados checar a permissão (role)
                      DocumentSnapshot userDoc = await FirebaseFirestore.instance
                          .collection('users') 
                          .doc(credential.user!.uid)
                          .get();

                      if (userDoc.exists && userDoc.data() != null) {
                        var userData = userDoc.data() as Map<String, dynamic>;
                        
                        if (userData['role'] == 'admin') {
                          // SUCESSO ABSOLUTO!
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Acesso Permitido! Bem-vindo, Admin.'), backgroundColor: Colors.green),
                          );
                          
                          // Navega para o Dashboard e não deixa o usuário voltar para o login clicando em "Voltar"
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const DashboardPage()),
                            );
                          }
                        } else {
                          // TEM CONTA, MAS NÃO É ADMIN
                          await FirebaseAuth.instance.signOut(); 
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Acesso Negado. Privilégios insuficientes.'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      } else {
                         // DOCUMENTO NÃO EXISTE NO FIRESTORE
                         await FirebaseAuth.instance.signOut();
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Registro de usuário não encontrado.'), backgroundColor: Colors.red),
                            );
                         }
                      }

                    } on FirebaseAuthException catch (e) {
                      // Log detalhado no console do VS Code
                      print('ERRO FIREBASE AUTH: ${e.code} -> ${e.message}');
                      
                      String mensagemErro = 'Erro: ${e.code}';
                      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
                        mensagemErro = 'Usuário não encontrado ou senha incorreta.';
                      } else if (e.code == 'invalid-email') {
                        mensagemErro = 'O formato do e-mail é inválido.';
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(mensagemErro), backgroundColor: Colors.red),
                      );
                    } catch (e) {
                      print('ERRO GERAL: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Erro interno do sistema.'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: Text(
                    'ENTRAR NO PAINEL',
                    style: GoogleFonts.roboto(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}