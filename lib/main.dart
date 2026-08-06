import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/supabase_service.dart';
import 'services/stripe_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.initialize();

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await StripeService.initialize();
      } catch (e) {
        debugPrint('Stripe initialization failed: $e');
      }
    }

    runApp(
      const ProviderScope(
        child: NuzulApp(),
      ),
    );
  } catch (e, stackTrace) {
    // ============ TEMPORARY CRASH DIAGNOSIS - REMOVE AFTER FIX ============
    debugPrint('FATAL STARTUP ERROR: $e');
    debugPrint('STACK TRACE: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red[900],
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STARTUP ERROR',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    e.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    stackTrace.toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // ============ END TEMPORARY CRASH DIAGNOSIS ============
  }
}