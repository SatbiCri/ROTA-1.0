class ParserOutputDTO {
  final double nominal;
  final int suggestedDebitAccountId;
  final int suggestedCreditAccountId;
  final String extractedKeyword;
  final bool isFromKnowledgeCache;

  ParserOutputDTO({
    required this.nominal,
    required this.suggestedDebitAccountId,
    required this.suggestedCreditAccountId,
    required this.extractedKeyword,
    required this.isFromKnowledgeCache,
  });

  factory ParserOutputDTO.empty() {
    return ParserOutputDTO(
      nominal: 0.0,
      suggestedDebitAccountId: 0,
      suggestedCreditAccountId: 0,
      extractedKeyword: '',
      isFromKnowledgeCache: false,
    );
  }
}
