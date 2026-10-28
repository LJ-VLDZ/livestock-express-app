import 'dart:math';

class DistanceHelper {
  // Key Alaminos City Barangays Reference Coordinates
  static const Map<String, Map<String, double>> barangayCoordinates = {
    'Poblacion': {'lat': 16.1556, 'lng': 119.9788},
    'Lucap': {'lat': 16.1824, 'lng': 119.9721},
    'Alos': {'lat': 16.1432, 'lng': 120.0215},
    'San Vicente': {'lat': 16.1689, 'lng': 119.9945},
    'Telbang': {'lat': 16.1321, 'lng': 119.9543},
    'Bolaney': {'lat': 16.1601, 'lng': 119.9520},
  };

  // Calculate distance in kilometers using the Haversine formula
  static double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    const int earthRadiusKm = 6371;

    double dLat = _degToRad(endLat - startLat);
    double dLon = _degToRad(endLng - startLng);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(startLat)) * cos(_degToRad(endLat)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  // Calculate transport fee (Returns ₱0 if buyer and seller are in the same barangay)
  static double calculateTransportFee(String sellerBarangay, String buyerBarangay) {
    if (sellerBarangay.trim().toLowerCase() == buyerBarangay.trim().toLowerCase()) {
      return 0.0; // Free Local Delivery within the same barangay
    }

    var origin = getBarangayCoords(sellerBarangay);
    var destination = getBarangayCoords(buyerBarangay);

    if (origin == null || destination == null) return 50.0; // Default base fee

    double distanceKm = calculateDistance(
        origin['lat']!, origin['lng']!,
        destination['lat']!, destination['lng']!
    );

    const double baseFare = 50.0;
    const double ratePerKm = 25.0;
    return baseFare + (distanceKm * ratePerKm);
  }

  static Map<String, double>? getBarangayCoords(String barangayName) {
    for (var entry in barangayCoordinates.entries) {
      if (entry.key.toLowerCase() == barangayName.toLowerCase()) {
        return entry.value;
      }
    }
    return barangayCoordinates['Poblacion']; // Default fallback
  }
}