import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'verification_guide_screen.dart';
import 'support_screen.dart';
import 'delivery_address_list_screen.dart';
import 'buyer_orders_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _softGreenTint = const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToVerificationGuide() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerificationGuideScreen()),
    );
  }

  void _showPersonalInformation(Map<String, dynamic> userData) {
    final TextEditingController nameController = TextEditingController(text: userData['name'] ?? userData['fullName'] ?? '');
    final TextEditingController phoneController = TextEditingController(text: userData['phone'] ?? '');
    final TextEditingController barangayController = TextEditingController(text: userData['barangay'] ?? '');
    final TextEditingController emailController = TextEditingController(text: userData['email'] ?? user?.email ?? '');

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Edit Personal Information", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _deepForestGreen)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text("Full Name", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "Enter full name",
                    prefixIcon: Icon(Icons.person_outline_rounded, color: _vibrantGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 14),
                Text("Contact Number", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: "09XXXXXXXXX",
                    prefixIcon: Icon(Icons.phone_android_rounded, color: _vibrantGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 14),
                Text("Barangay (Alaminos City)", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: barangayController,
                  decoration: InputDecoration(
                    hintText: "Enter or select barangay",
                    prefixIcon: Icon(Icons.location_on_outlined, color: _vibrantGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 14),
                Text("Email Address", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Enter email address",
                    prefixIcon: Icon(Icons.email_outlined, color: _vibrantGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _vibrantGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSaving ? null : () async {
                      setModalState(() => isSaving = true);
                      try {
                        if (user != null) {
                          String newEmail = emailController.text.trim();
                          String newName = nameController.text.trim();
                          String newPhone = phoneController.text.trim();
                          String newBarangay = barangayController.text.trim();

                          await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                            'name': newName,
                            'fullName': newName,
                            'phone': newPhone,
                            'barangay': newBarangay,
                            'email': newEmail,
                          });

                          if (newEmail.isNotEmpty && newEmail != user!.email) {
                            await user!.verifyBeforeUpdateEmail(newEmail);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            _showSnackBar("Profile updated successfully!");
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          _showSnackBar("Error updating profile: $e", isError: true);
                        }
                      } finally {
                        setModalState(() => isSaving = false);
                      }
                    },
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    bool pushEnabled = prefs.getBool('notif_push') ?? true;
    bool offersEnabled = prefs.getBool('notif_offers') ?? true;
    bool adminUpdatesEnabled = prefs.getBool('notif_admin') ?? true;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Notification Preferences", style: TextStyle(fontWeight: FontWeight.bold, color: _deepForestGreen)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text("Push Notifications", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text("Master switch for app alerts", style: TextStyle(fontSize: 12)),
                  value: pushEnabled,
                  activeColor: _vibrantGreen,
                  onChanged: (val) => setDialogState(() => pushEnabled = val),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text("Trade Offers & Inquiries", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text("Alerts for incoming chat messages and offers", style: TextStyle(fontSize: 12)),
                  value: offersEnabled,
                  activeColor: _vibrantGreen,
                  onChanged: pushEnabled ? (val) => setDialogState(() => offersEnabled = val) : null,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text("Admin & Verification Updates", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text("Alerts when ID verification or listings are approved", style: TextStyle(fontSize: 12)),
                  value: adminUpdatesEnabled,
                  activeColor: _vibrantGreen,
                  onChanged: pushEnabled ? (val) => setDialogState(() => adminUpdatesEnabled = val) : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _vibrantGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await prefs.setBool('notif_push', pushEnabled);
                await prefs.setBool('notif_offers', offersEnabled);
                await prefs.setBool('notif_admin', adminUpdatesEnabled);

                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar("Notification preferences saved!");
                }
              },
              child: const Text("Save Preferences", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold, color: _deepForestGreen)),
        content: const Text("Are you sure you want to log out of your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          _showSnackBar('Logout failed: $e', isError: true);
        }
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.red.shade700 : _vibrantGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FBF8),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Account",
                    style: TextStyle(color: _deepForestGreen, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text("Manage your profile and trading settings", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 40),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.green.shade100, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _softGreenTint,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person_off_rounded, size: 48, color: _vibrantGreen),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "No User Logged In",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _deepForestGreen),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Log in or register to view your profile, track purchases, and manage your livestock listings in Alaminos City.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _vibrantGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                                child: const Text("Log In / Register", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
            builder: (context, snapshot) {
              String verificationStatus = 'unverified';
              String fullName = "Livestock Trader";
              String contactNumber = "";
              double rating = 5.0;
              int ratingCount = 0;
              Map<String, dynamic> userData = {};

              if (snapshot.hasData && snapshot.data!.exists) {
                userData = snapshot.data!.data() as Map<String, dynamic>;
                verificationStatus = userData['verificationStatus'] ?? 'unverified';
                fullName = userData['name'] ?? userData['fullName'] ?? "Livestock Trader";
                contactNumber = userData['phone'] ?? userData['email'] ?? user!.email ?? "";
                rating = (userData['rating'] ?? 5.0).toDouble();
                ratingCount = (userData['ratingCount'] ?? 0).toInt();
              }

              Color statusColor;
              Color statusBgColor;
              String statusText;
              if (verificationStatus == 'verified') {
                statusColor = _vibrantGreen;
                statusBgColor = _softGreenTint;
                statusText = 'Verified Seller';
              } else if (verificationStatus == 'pending') {
                statusColor = Colors.orange.shade800;
                statusBgColor = Colors.orange.shade50;
                statusText = 'Verification Pending';
              } else {
                statusColor = Colors.red.shade700;
                statusBgColor = Colors.red.shade50;
                statusText = 'Unverified';
              }

              final bool isVerified = verificationStatus == 'verified';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Account",
                          style: TextStyle(color: _deepForestGreen, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text("Manage your profile and trading settings", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      children: [
                        // Profile Card with Ratings below Name & Contact
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade100, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: _softGreenTint,
                                child: Icon(Icons.person_rounded, size: 40, color: _vibrantGreen),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    fullName,
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _deepForestGreen),
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified_rounded, color: Colors.blue, size: 18),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                contactNumber,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${rating.toStringAsFixed(1)} ($ratingCount reviews)",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text("Seller Verification", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _deepForestGreen)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade100, width: 1),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "To ensure safety and build trust in Alaminos City livestock trading, posting listings requires admin verification.",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 18),
                              if (verificationStatus == 'unverified')
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _vibrantGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    icon: const Icon(Icons.verified_user_outlined),
                                    label: const Text("Submit ID for Verification", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    onPressed: _navigateToVerificationGuide,
                                  ),
                                )
                              else
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      verificationStatus == 'pending'
                                          ? "Your ID is currently under review by administrators."
                                          : "You are a verified seller! You have full access to post listings.",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade100, width: 1),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("My Purchases", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _deepForestGreen)),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const BuyerOrdersScreen(initialFilter: 'All')),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Text("View History", style: TextStyle(color: _vibrantGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _vibrantGreen),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildPurchaseShortcutItem(
                                    icon: Icons.account_balance_wallet_outlined,
                                    title: "To Pay",
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyerOrdersScreen(initialFilter: 'To Pay'))),
                                  ),
                                  _buildPurchaseShortcutItem(
                                    icon: Icons.inventory_2_outlined,
                                    title: "To Ship",
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyerOrdersScreen(initialFilter: 'To Ship'))),
                                  ),
                                  _buildPurchaseShortcutItem(
                                    icon: Icons.local_shipping_outlined,
                                    title: "To Receive",
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyerOrdersScreen(initialFilter: 'To Receive'))),
                                  ),
                                  _buildPurchaseShortcutItem(
                                    icon: Icons.star_border_rounded,
                                    title: "To Rate",
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyerOrdersScreen(initialFilter: 'To Rate'))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text("Settings & Preferences", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _deepForestGreen)),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade100, width: 1),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildAccountMenuItem(
                                icon: Icons.person_outline_rounded,
                                iconBgColor: const Color(0xFFEBF5FF),
                                iconColor: const Color(0xFF2563EB),
                                title: "Personal Information",
                                onTap: () => _showPersonalInformation(userData),
                              ),
                              const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFFF3F4F6)),
                              _buildAccountMenuItem(
                                icon: Icons.location_on_outlined,
                                iconBgColor: const Color(0xFFFEF3C7),
                                iconColor: const Color(0xFFD97706),
                                title: "Delivery Addresses",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const DeliveryAddressListScreen(isCheckoutMode: false)),
                                  );
                                },
                              ),
                              const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFFF3F4F6)),
                              _buildAccountMenuItem(
                                icon: Icons.notifications_outlined,
                                iconBgColor: const Color(0xFFF3E8FF),
                                iconColor: const Color(0xFF9333EA),
                                title: "Notification Preferences",
                                onTap: _showNotificationsSettings,
                              ),
                              const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFFF3F4F6)),
                              _buildAccountMenuItem(
                                icon: Icons.help_outline_rounded,
                                iconBgColor: const Color(0xFFFFFBEB),
                                iconColor: Colors.amber.shade800,
                                title: "Help & Support",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SupportScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text("Log Out", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            onPressed: () => _confirmAndLogout(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseShortcutItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _vibrantGreen, size: 24),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountMenuItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _deepForestGreen))),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}