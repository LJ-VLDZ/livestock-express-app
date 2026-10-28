class Livestock {
  final String name;
  final String description;
  final int price;
  final String status;
  final String ownerName; // Added field

  Livestock({
    required this.name,
    required this.description,
    required this.price,
    required this.status,
    required this.ownerName, // Added to constructor
  });

  Map<String, dynamic> toJson() => {
    'livestock_name': name,
    'description': description,
    'price': price,
    'status': status,
    'owner_name': ownerName, // Added to JSON
  };
}