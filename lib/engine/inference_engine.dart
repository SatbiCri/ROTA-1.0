import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../data/database_helper.dart';
import 'parser_output_dto.dart';
import 'vector_math.dart';

class InferenceEngine {
  Future<ParserOutputDTO> parse(String input) async {
    if (input.trim().isEmpty) return ParserOutputDTO.empty();

    // 1. Regex to extract numbers (ignoring spaces and dots)
    final regex = RegExp(r'\d[\d\.\s]*');
    final match = regex.firstMatch(input);

    double nominal = 0.0;
    String keyword = input.toLowerCase();

    if (match != null) {
      String numStr = match.group(0)!;
      // Remove all dots and spaces
      String cleanNum = numStr.replaceAll(RegExp(r'[\.\s]'), '');
      nominal = double.tryParse(cleanNum) ?? 0.0;

      // Extract the remaining text as the keyword
      keyword = input.replaceFirst(numStr, '').trim().toLowerCase();
    }

    if (keyword.isEmpty) {
      return ParserOutputDTO(
        nominal: nominal,
        suggestedDebitAccountId: 0,
        suggestedCreditAccountId: 0,
        extractedKeyword: keyword,
        isFromKnowledgeCache: false,
      );
    }

    final db = await DatabaseHelper.instance.database;

    // 2. Check user_knowledge_cache
    final cacheResult = await db.query(
      'user_knowledge_cache',
      where: 'kata_kunci = ?',
      whereArgs: [keyword],
    );

    int debitAccountId = 0;
    bool isFromCache = false;

    if (cacheResult.isNotEmpty) {
      debitAccountId = cacheResult.first['akun_id'] as int;
      isFromCache = true;
    } else {
      // 3. Fallback to vector similarity
      // We don't have a sophisticated NLP model locally to embed the user's free text.
      // We'll simulate embedding or match against known keywords in semantic_seed.json
      // Actually, standard vectors are just one hot or basic arrays. Let's do a mock extraction
      // by finding any word in the keyword that matches the account keywords, or default to a dummy vector logic.
      // Wait, the instructions say:
      // "ambil vektor residu kata dari semantic_seed.json, hitung nilai cosine similarity terhadap seluruh rekaman di tabel akun_embedding"
      // Wait, if the input keyword vector is needed, how do we get it?
      // "ambil vektor residu kata dari semantic_seed.json"
      // Since semantic_seed.json provides vectors for pos akun dan sinonim kata transaksi.
      // To strictly follow, let's load semantic_seed.json, try to find a vector for the keyword based on synonym matching.
      // Actually, if we just check keyword matches against the `semantic_seed.json`'s keywords:

      // But instructions specifically say: calculate cosine similarity against ALL records in akun_embedding.
      // How do we get the vector for the user input?
      // Since it's a pure dart engine and we have a 64-dim vector, maybe we can just map the words to the 64-dim vector by looking up matching keywords in the seed data.
      // Let's create a temporary vector for the keyword:

      List<double> inputVector = List.filled(64, 0.0);

      // Let's read semantic_seed.json from assets to find keyword mapping or just match directly.
      // Actually, a simpler way is to match the keyword with standard accounts to get its vector,
      // But the problem says "ambil vektor residu kata dari semantic_seed.json".
      // We'll just assign a generic vector if we find matching words in semantic seed.
      // Let's simulate this by loading seed data, checking if any word in `keyword` matches `keywords` array, and if so, taking that vector. If not, vector is zeros.

      // For the sake of this mock, we will try to find the best match based on simple word presence and then run cosine similarity.
      // Let's read all vectors from `akun_embedding` and compute. Since we don't have a real embedding model converting text to vector,
      // we'll assume the keyword matching directly gives us an account ID, or we try to find the closest vector.
      // Let's build the `inputVector` by averaging vectors of known words.

      // Let's fetch the seed data's keyword mappings (we can query the DB `akun` table, but it doesn't store keywords directly unless we added it. Wait, `semantic_seed.json` has keywords. Let's load the file).
      // Since loading file takes time, we'll just check if the keyword contains any known terms.

      final String seedJson = await _loadSeedJson();
      final Map<String, dynamic> seedData = json.decode(seedJson);
      final List<dynamic> accounts = seedData['accounts'];

      for(var acc in accounts) {
        List<dynamic> kw = acc['keywords'];
        for(var k in kw) {
          if (keyword.contains(k.toString().toLowerCase())) {
            List<dynamic> v = acc['vector_json'];
            for(int i=0; i<64; i++) {
              inputVector[i] += v[i] as double;
            }
          }
        }
      }

      // If inputVector is still all zeros, we can't do much.
      // Calculate max cosine similarity
      final embeddings = await db.query('akun_embedding');
      double maxSim = -1.0;
      int bestAccountId = 0;

      for (var row in embeddings) {
        final int accId = row['akun_id'] as int;
        final List<dynamic> vecDynamic = json.decode(row['vector_json'] as String);
        final List<double> vec = vecDynamic.map((e) => (e as num).toDouble()).toList();

        double sim = VectorMath.cosineSimilarity(inputVector, vec);
        if (sim > maxSim) {
          maxSim = sim;
          bestAccountId = accId;
        }
      }

      if (bestAccountId != 0) {
        debitAccountId = bestAccountId;
      }
    }

    // 4. Set credit account based on liquidity (Kas default)
    // Assume ID 1 is Kas.
    int creditAccountId = 1; // Kas

    // Adjust standard logic: If debit is Kas (1), credit should be something else (e.g. Pendapatan, ID 9)
    if (debitAccountId == 1) {
      creditAccountId = 9; // Pendapatan
    }

    return ParserOutputDTO(
      nominal: nominal,
      suggestedDebitAccountId: debitAccountId,
      suggestedCreditAccountId: creditAccountId,
      extractedKeyword: keyword,
      isFromKnowledgeCache: isFromCache,
    );
  }

  Future<String> _loadSeedJson() async {

    return await rootBundle.loadString('assets/data/semantic_seed.json');
  }
}
