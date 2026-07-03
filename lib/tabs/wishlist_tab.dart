import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistTab extends StatefulWidget {
  const WishlistTab({super.key});

  @override
  State<WishlistTab> createState() => _WishlistTabState();
}

class _WishlistTabState extends State<WishlistTab> {
  String? _usuarioSelecionadoId;
  String? _usuarioSelecionadoEmail;

  // --- DICIONÁRIO DE PRODUTOS COM IMAGEM ---
  Map<String, dynamic> _obterDadosProduto(String idProduto) {
    final produtos = {
      'API_10': {'nome': 'SanDisk SSD PLUS 1TB', 'imagem': 'assets/produtos/ssd.jpg'},
      'API_13': {'nome': 'Acer SB220Q bi 21.5', 'imagem': 'assets/produtos/monitor.jpg'},
      'API_12': {'nome': 'WD 4TB Gaming Drive', 'imagem': 'assets/produtos/hd.jpg'},
      'API_9':  {'nome': 'WD 2TB Elements', 'imagem': 'assets/produtos/hd.jpg'},
      'API_11': {'nome': 'Silicon Power 256GB', 'imagem': 'assets/produtos/ssd.jpg'},
      'API_14': {'nome': 'Samsung 49-Inch CHG90', 'imagem': 'assets/produtos/monitor.jpg'},
    };

    if (produtos.containsKey(idProduto)) {
      return produtos[idProduto]!;
    }
    return {
      'nome': 'Produto $idProduto',
      'imagem': 'assets/ORANGE-ICON.png',
    };
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
            : _buildWishlistDoUsuario(),
      ),
    );
  }

  // ==========================================
  // FASE 1: LISTA DE USUÁRIOS
  // ==========================================
  Widget _buildListaUsuarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Selecione um usuário para ver a Lista de Desejos',
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
                return const Center(child: Text('Erro ao carregar usuários.'));
              }

              final usuarios = snapshot.data?.docs ?? [];

              if (usuarios.isEmpty) {
                return const Center(child: Text('Nenhum usuário encontrado no banco.'));
              }

              return ListView.separated(
                itemCount: usuarios.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = usuarios[index];
                  final dados = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  
                  // 1. Tenta pegar o campo 'nome'
                  // 2. Se não existir, tenta o 'name' (caso esteja em inglês no banco)
                  // 3. Se não tiver nenhum dos dois, cai para o 'email'
                  // 4. Se não tiver absolutamente nada, mostra 'Usuário não identificado'
                  final nomeExibicao = dados['nome'] ?? dados['name'] ?? dados['email'] ?? 'Usuário não identificado';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(nomeExibicao, style: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: Colors.black87)), // <-- Atualizado aqui
                    subtitle: Text('ID: $id', style: GoogleFonts.roboto(color: Colors.black54, fontSize: 12)),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.card_giftcard, size: 18),
                      label: const Text('Ver Wishlist'),
                      onPressed: () {
                        setState(() {
                          _usuarioSelecionadoId = id;
                          // Passamos o nome para aparecer bonitinho no topo da Fase 2 também
                          _usuarioSelecionadoEmail = nomeExibicao; 
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
  // FASE 2: WISHLIST DO USUÁRIO
  // ==========================================
  Widget _buildWishlistDoUsuario() {
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
                    'Lista de Desejos (Wishlist)',
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
            // Buscando a coleção wishlist que fica dentro do documento do usuário
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_usuarioSelecionadoId)
                .collection('wishlist')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Erro ao carregar a wishlist deste usuário.'));
              }

              final itens = snapshot.data?.docs ?? [];

              if (itens.isEmpty) {
                return const Center(child: Text('A wishlist deste usuário está vazia.'));
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
                        DataColumn(label: Text('Produto')),
                        DataColumn(label: Text('Código ID')),
                      ],
                      rows: itens.map((doc) {
                        // Tenta extrair o idProduto. Se não existir o campo, assume que o ID do documento é o id do produto.
                        final dados = doc.data() as Map<String, dynamic>;
                        final String idProdutoCru = dados.containsKey('idProduto') ? dados['idProduto'] : doc.id;
                        
                        final dadosProduto = _obterDadosProduto(idProdutoCru);

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      dadosProduto['imagem'],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 40, height: 40, color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    dadosProduto['nome'],
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(idProdutoCru)),
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