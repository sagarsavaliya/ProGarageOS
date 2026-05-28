class CatalogOption {
  final String uuid;
  final String name;
  final String? fuelType;
  final String? transmission;
  final String? bodyType;

  const CatalogOption({
    required this.uuid,
    required this.name,
    this.fuelType,
    this.transmission,
    this.bodyType,
  });

  factory CatalogOption.fromJson(Map<String, dynamic> json) => CatalogOption(
        uuid: json['uuid'] as String? ?? '',
        name: json['name'] as String? ?? '',
        fuelType: json['fuel_type'] as String?,
        transmission: json['transmission'] as String?,
        bodyType: json['body_type'] as String?,
      );
}
