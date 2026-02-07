class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? address;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'phone': phone, 'address': address};
  }
}
