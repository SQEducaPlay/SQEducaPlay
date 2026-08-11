class School {
  final String id;
  final String name;
  final String? address;
  final String? city;

  School({
    required this.id,
    required this.name,
    this.address,
    this.city,
  });

  @override
  String toString() => name;
}
