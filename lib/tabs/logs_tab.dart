import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LogsTab extends StatefulWidget {
  const LogsTab({super.key});

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  String? _usuarioSelecionadoId;
  String? _usuarioSelecionadoEmail;

  // Função para formatar a data
  String _formatarData(int timestampMs) {
    DateTime data = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    String dia = data.day.toString().padLeft(2, '0');
    String mes = data.month.toString().padLeft(2, '0');
    String ano = data.year.toString();
    String hora = data.hour.toString().padLeft(2, '0');
    String minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano às $hora:$minuto';
  }

  // --- DICIONÁRIO TRADUTOR DE PRODUTOS ---
  String _obterNomeProduto(String idProduto) {
    final produtos = {
      'API_10': 'SanDisk SSD PLUS 1TB',
      'API_13': 'Acer SB220Q bi 21.5',
      'API_12': 'WD 4TB Gaming Drive',
      'API_9':  'WD 2TB Elements',
      'API_11': 'Silicon Power 256GB',
      'API_14': 'Samsung 49-Inch CHG90',
    };
    // Se o ID não estiver na lista, mostra o ID original ao invés de quebrar a tela
    return produtos[idProduto] ?? 'Produto $idProduto';
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
        child: _usuarioSelecionadoId == null 
            ? _buildListaUsuarios() 
            : _buildLogsDoUsuario(),
      ),
    );
  }

  // ==========================================
  // TELA 1: LISTA DE USUÁRIOS
  // ==========================================
  Widget _buildListaUsuarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Selecione um utilizador para auditar',
            style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
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
                return const Center(child: Text('Erro ao carregar utilizadores.'));
              }

              final usuarios = snapshot.data?.docs ?? [];

              if (usuarios.isEmpty) {
                return const Center(child: Text('Nenhum utilizador encontrado.'));
              }

              return ListView.separated(
                itemCount: usuarios.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = usuarios[index];
                  final dados = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  
                  // Lógica idêntica de humanização
                  final nomeExibicao = dados['nome'] ?? dados['name'] ?? dados['email'] ?? 'Utilizador não identificado';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(nomeExibicao, style: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: Colors.black87)), // <-- Nome aqui
                    subtitle: Text('ID: $id', style: GoogleFonts.roboto(color: Colors.black54, fontSize: 12)),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Ver Histórico'),
                      onPressed: () {
                        setState(() {
                          _usuarioSelecionadoId = id;
                          _usuarioSelecionadoEmail = nomeExibicao; // <-- Passa o nome para o cabeçalho da Fase 2
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TELA 2: LOGS INDIVIDUAIS
  // ==========================================
  Widget _buildLogsDoUsuario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  setState(() {
                    _usuarioSelecionadoId = null;
                    _usuarioSelecionadoEmail = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Histórico de Atividade',
                    style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    _usuarioSelecionadoEmail ?? '',
                    style: GoogleFonts.roboto(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('admin_logs') 
                .doc(_usuarioSelecionadoId)
                .collection('logs')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Erro ao carregar os logs deste usuário.'));
              }

              final logs = snapshot.data?.docs ?? [];

              if (logs.isEmpty) {
                return const Center(child: Text('Nenhuma atividade registrada para este usuário.'));
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal, 
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 330),
                    child: DataTable(
                      headingTextStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: Colors.black87),
                      dataTextStyle: GoogleFonts.roboto(color: Colors.black54),
                      columns: const [
                        DataColumn(label: Text('Data e Hora')),
                        DataColumn(label: Text('Ação')),
                        DataColumn(label: Text('Produto Afetado')),
                      ],
                      rows: logs.map((doc) {
                        final dados = doc.data() as Map<String, dynamic>;
                        final timestamp = dados['timestamp'] ?? 0;
                        final tipo = dados['tipo'] ?? 'Desconhecido';
                        
                        // Pegamos o ID e passamos no nosso tradutor!
                        final idProdutoCru = dados['idProduto'] ?? '';
                        final nomeRealDoProduto = _obterNomeProduto(idProdutoCru);

                        bool isLike = tipo == 'NOVO_LIKE';

                        return DataRow(
                          cells: [
                            DataCell(Text(_formatarData(timestamp))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isLike ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  tipo,
                                  style: TextStyle(
                                    color: isLike ? Colors.green[800] : Colors.red[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            // Desenhando o nome traduzido
                            DataCell(Text(nomeRealDoProduto, style: const TextStyle(fontWeight: FontWeight.w500))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}