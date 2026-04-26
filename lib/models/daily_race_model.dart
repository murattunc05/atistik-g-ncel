class DailyRaceModel {
  String time;
  String raceNo;
  String raceName;
  String distance;
  String trackType;
  String prize;
  String city;
  String raceId;  // TJK koşu kodu (idman bilgileri için)
  List<RunningHorse> horses;

  DailyRaceModel({
    required this.time,
    required this.raceNo,
    required this.city,
    required this.raceName,
    required this.distance,
    required this.trackType,
    required this.prize,
    this.raceId = '',
    this.horses = const [],
  });

  factory DailyRaceModel.fromJson(Map<String, dynamic> json) {
    return DailyRaceModel(
      time: json['time'] ?? '',
      raceNo: json['raceNo'] ?? '',
      city: json['city'] ?? '',
      raceName: json['raceName'] ?? '',
      distance: json['distance'] ?? '',
      trackType: json['trackType'] ?? '',
      prize: json['prize'] ?? '',
      raceId: json['raceId'] ?? '',
      horses: (json['horses'] as List<dynamic>?)
              ?.map((e) => RunningHorse.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'raceNo': raceNo,
      'city': city,
      'raceName': raceName,
      'distance': distance,
      'trackType': trackType,
      'prize': prize,
      'raceId': raceId,
      'horses': horses.map((e) => e.toJson()).toList(),
    };
  }
}

class RunningHorse {
  final String no;
  final String name;
  final String jockey;
  final String weight;
  final String age;
  final String owner;
  final String last6;
  final String father;
  final String mother;
  final String trainer;
  final String hp;
  final String kgs;
  final String s20;
  final String bestRating;
  final String agf;
  final String detailLink; // TJK at detay sayfası linki

  RunningHorse({
    required this.no,
    required this.name,
    required this.jockey,
    required this.weight,
    this.age = '',
    this.owner = '',
    this.last6 = '',
    this.father = '',
    this.mother = '',
    this.trainer = '',
    this.hp = '',
    this.kgs = '',
    this.s20 = '',
    this.bestRating = '',
    this.agf = '',
    this.detailLink = '',
  });

  factory RunningHorse.fromJson(Map<String, dynamic> json) {
    return RunningHorse(
      no: json['no'] ?? '',
      name: json['name'] ?? '',
      jockey: json['jockey'] ?? '',
      weight: json['weight'] ?? '',
      age: json['age'] ?? '',
      owner: json['owner'] ?? '',
      last6: json['last6'] ?? '',
      father: json['father'] ?? '',
      mother: json['mother'] ?? '',
      trainer: json['trainer'] ?? '',
      hp: json['hp'] ?? '',
      kgs: json['kgs'] ?? '',
      s20: json['s20'] ?? '',
      bestRating: json['bestRating'] ?? '',
      agf: json['agf'] ?? '',
      detailLink: json['detailLink'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'no': no,
      'name': name,
      'jockey': jockey,
      'weight': weight,
      'age': age,
      'owner': owner,
      'last6': last6,
      'father': father,
      'mother': mother,
      'trainer': trainer,
      'hp': hp,
      'kgs': kgs,
      's20': s20,
      'bestRating': bestRating,
      'agf': agf,
      'detailLink': detailLink,
    };
  }
}
