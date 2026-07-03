import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Adicionado para buscar o nome
import 'login_page.dart';

import 'tabs/visao_geral_tab.dart';
import 'tabs/usuarios_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/wishlist_tab.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _indiceAtual = 0; 
  String _nomeAdmin = 'A carregar...'; // <-- Variável para guardar o nome

  @override
  void initState() {
    super.initState();
    _carregarDadosAdmin(); // Assim que a tela abre, vai procurar o nome
  }

  // --- Função para buscar o nome de quem fez login ---
  Future<void> _carregarDadosAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final dados = doc.data() as Map<String, dynamic>;
          // Usa a mesma lógica: tenta o nome, senão o email, senão "Admin"
          final nomeExibicao = dados['nome'] ?? dados['name'] ?? dados['email'] ?? 'Administrador';
          
          if (mounted) {
            setState(() {
              _nomeAdmin = nomeExibicao;
            });
          }
        } else {
          if (mounted) {
            setState(() => _nomeAdmin = user.email ?? 'Administrador');
          }
        }
      } catch (e) {
        if (mounted) setState(() => _nomeAdmin = 'Administrador');
      }
    }
  }

  void _fazerLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Instanciando as classes modulares
    final List<Widget> telas = [
      const VisaoGeralTab(),
      const UsuariosTab(),
      const LogsTab(),
      const WishlistTab(),
    ];

    final List<String> titulos = [
      'Visão Geral do Sistema',
      'Gestão de Usuários',
      'Logs por usuário',
      'Wishlists',
    ];

    return Scaffold(
      body: Row(
        children: [
          // --- MENU LATERAL (SIDEBAR) ---
          Material( 
            color: Colors.black, 
            child: SizedBox(
              width: 260,
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Image.asset('assets/ORANGE-ICON.png', height: 70),
                  const SizedBox(height: 12),
                  Text(
                    'PAPOCO ADMIN',
                    style: GoogleFonts.fugazOne(color: Colors.white, fontSize: 22),
                  ),
                  const SizedBox(height: 48),
                  
                  ListTile(
                    leading: Icon(Icons.dashboard, color: _indiceAtual == 0 ? Colors.white : Colors.white70),
                    title: Text(
                      'Visão Geral', 
                      style: GoogleFonts.roboto(
                        color: _indiceAtual == 0 ? Colors.white : Colors.white70, 
                        fontWeight: _indiceAtual == 0 ? FontWeight.bold : FontWeight.normal
                      )
                    ),
                    tileColor: _indiceAtual == 0 ? Colors.white.withOpacity(0.1) : Colors.transparent,
                    onTap: () {
                      setState(() { _indiceAtual = 0; });
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.people, color: _indiceAtual == 1 ? Colors.white : Colors.white70),
                    title: Text(
                      'Usuários Cadastrados', 
                      style: GoogleFonts.roboto(
                        color: _indiceAtual == 1 ? Colors.white : Colors.white70, 
                        fontWeight: _indiceAtual == 1 ? FontWeight.bold : FontWeight.normal
                      )
                    ),
                    tileColor: _indiceAtual == 1 ? Colors.white.withOpacity(0.1) : Colors.transparent,
                    onTap: () {
                      setState(() { _indiceAtual = 1; });
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.history, color: _indiceAtual == 2 ? Colors.white : Colors.white70),
                    title: Text(
                      'Logs de Atividade', 
                      style: GoogleFonts.roboto(
                        color: _indiceAtual == 2 ? Colors.white : Colors.white70, 
                        fontWeight: _indiceAtual == 2 ? FontWeight.bold : FontWeight.normal
                      )
                    ),
                    tileColor: _indiceAtual == 2 ? Colors.white.withOpacity(0.1) : Colors.transparent,
                    onTap: () {
                      setState(() { _indiceAtual = 2; });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.star, color: _indiceAtual == 3 ? Colors.white : Colors.white70),
                    title: Text(
                      'Wishlists', 
                      style: GoogleFonts.roboto(
                        color: _indiceAtual == 3 ? Colors.white : Colors.white70, 
                        fontWeight: _indiceAtual == 3 ? FontWeight.bold : FontWeight.normal
                      )
                    ),
                    tileColor: _indiceAtual == 3 ? Colors.white.withOpacity(0.1) : Colors.transparent,
                    onTap: () {
                      setState(() { _indiceAtual = 3; });
                    },
                  ),
                  
                  const Spacer(), 
                  
                  ListTile(
                    leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
                    title: Text('Sair do Sistema', style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    onTap: () => _fazerLogout(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // --- ÁREA DE CONTEÚDO PRINCIPAL ---
          Expanded(
            child: Container(
              color: const Color(0xFFF5F6FA), 
              child: Column(
                children: [
                  Container(
                    height: 80,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          titulos[_indiceAtual], 
                          style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Row(
                          children: [
                            // <-- AQUI ESTÁ A MÁGICA: Agora usa a variável com o nome do utilizador!
                            Text(_nomeAdmin, style: GoogleFonts.roboto(fontWeight: FontWeight.w500, color: Colors.black54)),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  
                  // Injeção limpa da tela
                  Expanded(
                    child: telas[_indiceAtual],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}