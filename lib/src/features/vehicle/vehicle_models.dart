class Vehicle {
  const Vehicle({
    required this.vehicleId,
    required this.nickname,
    required this.plate,
    required this.vin,
    required this.brand,
    required this.model,
    required this.year,
    required this.engine,
    required this.fuelType,
    required this.transmission,
    required this.currentMileage,
  });

  final String vehicleId;
  final String? nickname;
  final String plate;
  final String? vin;
  final String brand;
  final String model;
  final int year;
  final String? engine;
  final String? fuelType;
  final String? transmission;
  final int currentMileage;

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicleId']?.toString() ?? '',
      nickname: json['nickname']?.toString(),
      plate: json['plate']?.toString() ?? '',
      vin: json['vin']?.toString(),
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: int.tryParse(json['year']?.toString() ?? '') ?? 0,
      engine: json['engine']?.toString(),
      fuelType: json['fuelType']?.toString(),
      transmission: json['transmission']?.toString(),
      currentMileage:
          int.tryParse(json['currentMileage']?.toString() ?? '') ?? 0,
    );
  }
}
