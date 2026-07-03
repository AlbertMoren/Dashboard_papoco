import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Necessário para o Reset de Senha

class UsuariosTab extends StatefulWidget {
  const UsuariosTab({super.key});

  @override
  State<UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<UsuariosTab> {
  String _termoPesquisa = '';

  // --- FUNÇÃO 1: Alterar Nível de Acesso ---
  Future<void> _alterarNivelAcesso(String id, String roleAtual) async {
    final novoRole = roleAtual == 'admin' ? 'user' : 'admin';
    try {
      await FirebaseFirestore.instance.collection('users').doc(id).update({'role': novoRole});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permissão atualizada para $novoRole!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar permissão.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- FUNÇÃO 2: Excluir Conta ---
  void _confirmarExclusao(String id, String nome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Usuário?'),
        content: Text('Tem certeza que deseja excluir os dados de "$nome"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('users').doc(id).delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuário excluído com sucesso.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Sim, Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FUNÇÃO 3: Reset de Senha via E-mail ---
  Future<void> _enviarEmailRedefinicao(String email) async {
    if (email.isEmpty || email == 'Sem e-mail') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este usuário não possui um e-mail válido cadastrado.'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Link de redefinição enviado para $email'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar e-mail de redefinição.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- FUNÇÃO 4: Modal para Editar Dados (Nome) ---
  void _abrirModalEdicao(String id, String nomeAtual) {
    final TextEditingController nomeController = TextEditingController(text: nomeAtual == 'Utilizador não identificado' ? '' : nomeAtual);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Dados do Usuário'),
        content: TextField(
          controller: nomeController,
          decoration: InputDecoration(
            labelText: 'Nome do Usuário',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Fecha o modal
              
              // Atualiza ou cria o campo 'nome' no documento do Firestore
              await FirebaseFirestore.instance.collection('users').doc(id).update({
                'nome': nomeController.text.trim(),
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dados atualizados com sucesso!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Salvar Alterações'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Controle de Acesso e Gestão',
                    style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Pesquisar por nome ou ID...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      onChanged: (valor) {
                        setState(() {
                          _termoPesquisa = valor.toLowerCase();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Erro ao carregar os dados.'));
                  }

                  var usuarios = snapshot.data?.docs ?? [];

                  if (_termoPesquisa.isNotEmpty) {
                    usuarios = usuarios.where((doc) {
                      final dados = doc.data() as Map<String, dynamic>;
                      final nomeExibicao = (dados['nome'] ?? dados['name'] ?? dados['email'] ?? '').toString().toLowerCase();
                      final id = doc.id.toLowerCase();
                      return nomeExibicao.contains(_termoPesquisa) || id.contains(_termoPesquisa);
                    }).toList();
                  }

                  if (usuarios.isEmpty) {
                    return const Center(child: Text('Nenhum utilizador encontrado com esse filtro.'));
                  }

                  return SingleChildScrollView(
                    child: SizedBox( // <--- 1. ADICIONE ESTE SIZEDBOX
                      width: double.infinity, // <--- 2. FORÇA A LARGURA MÁXIMA
                      child: DataTable(
                        headingTextStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: Colors.black87),
                        dataTextStyle: GoogleFonts.roboto(color: Colors.black54),
                        columns: const [
                          DataColumn(label: Text('ID do Utilizador')),
                          DataColumn(label: Text('Nome / E-mail')),
                          DataColumn(label: Text('Nível')),
                          DataColumn(label: Text('Ações')), 
                        ],
                        rows: usuarios.map((doc) {
                          final dados = doc.data() as Map<String, dynamic>;
                          final id = doc.id;
                          final nomeExibicao = dados['nome'] ?? dados['name'] ?? dados['email'] ?? 'Utilizador não identificado';
                          final emailOriginal = dados['email'] ?? '';
                          final role = dados.containsKey('role') ? dados['role'] : 'user';

                          return DataRow(
                            cells: [
                              DataCell(Text(id, style: const TextStyle(fontSize: 12))),
                              DataCell(Text(nomeExibicao, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: role == 'admin' ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    role.toUpperCase(),
                                    style: TextStyle(
                                      color: role == 'admin' ? Colors.orange[800] : Colors.blue[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                PopupMenuButton<String>(
                                  onSelected: (valor) {
                                    if (valor == 'mudar_permissao') {
                                      _alterarNivelAcesso(id, role);
                                    } else if (valor == 'editar') {
                                      _abrirModalEdicao(id, nomeExibicao);
                                    } else if (valor == 'reset_senha') {
                                      _enviarEmailRedefinicao(emailOriginal);
                                    } else if (valor == 'excluir') {
                                      _confirmarExclusao(id, nomeExibicao);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem(
                                      value: 'editar',
                                      child: Row(
                                        children: const [
                                          Icon(Icons.edit, color: Colors.blueGrey, size: 20),
                                          SizedBox(width: 8),
                                          Text('Editar Nome'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'reset_senha',
                                      child: Row(
                                        children: const [
                                          Icon(Icons.lock_reset, color: Colors.orange, size: 20),
                                          SizedBox(width: 8),
                                          Text('Resetar Senha'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'mudar_permissao',
                                      child: Row(
                                        children: [
                                          Icon(role == 'admin' ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.blue, size: 20),
                                          const SizedBox(width: 8),
                                          Text(role == 'admin' ? 'Rebaixar a Usuário' : 'Promover a Admin'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: 'excluir',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red, size: 20),
                                          SizedBox(width: 8),
                                          Text('Excluir Conta', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ), // FECHA O DATATABLE
                    ), // FECHA O SIZEDBOX
                  ); // FECHA O SINGLECHILDSCROLLVIEW
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}