import 'package:flutter/material.dart';

void showTermsAndConditions(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Terms & Conditions", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A3622))),
      content: const SingleChildScrollView(
        child: Text(
          "Welcome to Livestock Express!\n\n"
              "1. **Platform Purpose**: Livestock Express serves as a digital trading and logistics marketplace connecting farmers, buyers, and livestock traders within Alaminos City and surrounding regions.\n\n"
              "2. **Verified Transactions**: All listings, trade offers, and transport fees must comply with local agricultural guidelines. Misrepresentation of livestock breed, health status, or pricing may result in account suspension.\n\n"
              "3. **Delivery & Transport Fees**: Transport fee calculations are estimates based on distance mapping from the seller's location to the delivery address within Pangasinan.\n\n"
              "4. **User Responsibility**: Users are solely responsible for verifying livestock conditions upon meetup or delivery. Livestock Express is not liable for private agreements made outside official app protocols.",
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close", style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}