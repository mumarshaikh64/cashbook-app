class PartyModel {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final double cashIn;
  final double cashOut;

  PartyModel({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.cashIn = 0.0,
    this.cashOut = 0.0,
  });

  // Net Balance for the party
  // Positive balance means we received more cash from them.
  // Negative balance means we paid more cash to them (outstanding receivables/payables depending on context).
  double get balance => cashIn - cashOut;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
    };
  }

  factory PartyModel.fromMap(Map<String, dynamic> map, {double cashIn = 0.0, double cashOut = 0.0}) {
    return PartyModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      cashIn: cashIn,
      cashOut: cashOut,
    );
  }
}
