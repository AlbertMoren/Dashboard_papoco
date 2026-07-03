import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VisaoGeralTab extends StatelessWidget {
  const VisaoGeralTab({super.key});

  Map<String, dynamic> _obterDadosProduto(String idProduto) {
    // Usando o CorsProxy.io, a solução mais robusta para testes no Flutter Web
    const proxy = 'https://corsproxy.io/?';
    
    final fakeApi = {
      'API_10': {'nome': 'SanDisk SSD PLUS 1TB', 'imagem': '${proxy}https://fakestoreapi.com/img/61U7T1koQqL._AC_SX679_.jpg'},
      'API_13': {'nome': 'Acer SB220Q bi 21.5', 'imagem': '${proxy}https://fakestoreapi.com/img/81QpkIctqPL._AC_SX679_.jpg'},
      'API_12': {'nome': 'WD 4TB Gaming Drive', 'imagem': '${proxy}https://fakestoreapi.com/img/61mtL65D4cG._AC_SX679_.jpg'},
      'API_9':  {'nome': 'WD 2TB Elements', 'imagem': '${proxy}https://fakestoreapi.com/img/61IBBVJvSDL._AC_SY879_.jpg'},
      'API_11': {'nome': 'Silicon Power 256GB', 'imagem': '${proxy}https://fakestoreapi.com/img/71kWymZ+c+L._AC_SX679_.jpg'},
      'API_14': {'nome': 'Samsung 49-Inch CHG90', 'imagem': '${proxy}https://fakestoreapi.com/img/81Zt42O025L._AC_SX679_.jpg'},
    };

    if (fakeApi.containsKey(idProduto)) {
      return fakeApi[idProduto]!;
    }

    return {
      'nome': 'Produto $idProduto',
      'imagem': 'https://picsum.photos/seed/$idProduto/100/100',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Métricas de Engajamento',
            style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collectionGroup('logs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao ler os logs.'));
                }

                final logs = snapshot.data?.docs ?? [];

                if (logs.isEmpty) {
                  return const Center(child: Text('Nenhum dado de engajamento encontrado.'));
                }

                // PROCESSAMENTO DOS DADOS
                int totalLikes = 0;
                Map<String, int> likesPorProduto = {};

                for (var doc in logs) {
                  final data = doc.data() as Map<String, dynamic>;
                  
                  if (data['tipo'] == 'NOVO_LIKE') {
                    totalLikes++;
                    String idProd = data['idProduto'] ?? 'Desconhecido';
                    likesPorProduto[idProd] = (likesPorProduto[idProd] ?? 0) + 1;
                  }
                }

                var rankingProdutos = likesPorProduto.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                int maxLikes = rankingProdutos.isNotEmpty ? rankingProdutos.first.value : 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CARD 1: Total de Likes
                    Container(
                      width: 250,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Text('Total de Matches', style: GoogleFonts.roboto(color: Colors.black54, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            totalLikes.toString(),
                            style: GoogleFonts.fugazOne(fontSize: 48, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),

                    // CARD 2: Ranking de Produtos com Foto e Nome
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
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
                            Text('Top Produtos (Matches)', style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 24),
                            
                            Expanded(
                              child: ListView.builder(
                                itemCount: rankingProdutos.length,
                                itemBuilder: (context, index) {
                                  final item = rankingProdutos[index];
                                  final proporcao = item.value / maxLikes; 
                                  
                                  // Chama o simulador da API para pegar foto e nome baseado na chave
                                  final dadosProduto = _obterDadosProduto(item.key);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Row(
                                      children: [
                                        // ÁREA DO PRODUTO (Foto + Nome)
                                        SizedBox(
                                          width: 220, // Mais largo para caber a foto
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Image.network(
                                                  dadosProduto['imagem'],
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                  // Mostra um ícone cinza se o link da imagem estiver quebrado
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    width: 40, height: 40, color: Colors.grey[200],
                                                    child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  dadosProduto['nome'],
                                                  style: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 13),
                                                  overflow: TextOverflow.ellipsis, // Coloca "..." se o nome for grande
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // BARRA DO GRÁFICO
                                        Expanded(
                                          child: Stack(
                                            children: [
                                              Container(
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              FractionallySizedBox(
                                                widthFactor: proporcao,
                                                child: Container(
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primary, 
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // QUANTIDADE
                                        SizedBox(
                                          width: 40,
                                          child: Text(
                                            item.value.toString(),
                                            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}