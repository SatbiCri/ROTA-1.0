class Akun {
  final int? id;
  final String kodeAkun;
  final String namaAkun;
  final String kategori;
  final String posisiNormal;

  Akun({
    this.id,
    required this.kodeAkun,
    required this.namaAkun,
    required this.kategori,
    required this.posisiNormal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode_akun': kodeAkun,
      'nama_akun': namaAkun,
      'kategori': kategori,
      'posisi_normal': posisiNormal,
    };
  }

  factory Akun.fromMap(Map<String, dynamic> map) {
    return Akun(
      id: map['id'],
      kodeAkun: map['kode_akun'],
      namaAkun: map['nama_akun'],
      kategori: map['kategori'],
      posisiNormal: map['posisi_normal'],
    );
  }
}

class Transaksi {
  final int? id;
  final String tanggal;
  final String teksAsli;
  final double nominal;

  Transaksi({
    this.id,
    required this.tanggal,
    required this.teksAsli,
    required this.nominal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal': tanggal,
      'teks_asli': teksAsli,
      'nominal': nominal,
    };
  }

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'],
      tanggal: map['tanggal'],
      teksAsli: map['teks_asli'],
      nominal: map['nominal'],
    );
  }
}

class JurnalDetail {
  final int? id;
  final int transaksiId;
  final int akunId;
  final double debit;
  final double kredit;

  JurnalDetail({
    this.id,
    required this.transaksiId,
    required this.akunId,
    this.debit = 0,
    this.kredit = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaksi_id': transaksiId,
      'akun_id': akunId,
      'debit': debit,
      'kredit': kredit,
    };
  }

  factory JurnalDetail.fromMap(Map<String, dynamic> map) {
    return JurnalDetail(
      id: map['id'],
      transaksiId: map['transaksi_id'],
      akunId: map['akun_id'],
      debit: map['debit'],
      kredit: map['kredit'],
    );
  }
}

class UserKnowledgeCache {
  final int? id;
  final String kataKunci;
  final int akunId;
  final int frekuensi;
  final String terakhirDipakai;

  UserKnowledgeCache({
    this.id,
    required this.kataKunci,
    required this.akunId,
    this.frekuensi = 1,
    required this.terakhirDipakai,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kata_kunci': kataKunci,
      'akun_id': akunId,
      'frekuensi': frekuensi,
      'terakhir_dipakai': terakhirDipakai,
    };
  }

  factory UserKnowledgeCache.fromMap(Map<String, dynamic> map) {
    return UserKnowledgeCache(
      id: map['id'],
      kataKunci: map['kata_kunci'],
      akunId: map['akun_id'],
      frekuensi: map['frekuensi'],
      terakhirDipakai: map['terakhir_dipakai'],
    );
  }
}

class AkunEmbedding {
  final int akunId;
  final String vectorJson;

  AkunEmbedding({
    required this.akunId,
    required this.vectorJson,
  });

  Map<String, dynamic> toMap() {
    return {
      'akun_id': akunId,
      'vector_json': vectorJson,
    };
  }

  factory AkunEmbedding.fromMap(Map<String, dynamic> map) {
    return AkunEmbedding(
      akunId: map['akun_id'],
      vectorJson: map['vector_json'],
    );
  }
}
