import 'package:coffee_flutter/widgets/payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:moyasar/moyasar.dart';

import 'widgets/coffee.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      locale: Locale('ar'),
      debugShowCheckedModeBanner: false,
      home: CoffeeShop(),
    );
  }
}

class CoffeeShop extends StatefulWidget {
  const CoffeeShop({super.key});

  @override
  State<CoffeeShop> createState() => _CoffeeShopState();
}

class _CoffeeShopState extends State<CoffeeShop> {
  final paymentConfig = PaymentConfig(
      publishableApiKey: 'pk_test_jQkxWxReHEog5sxHqGohpkbM6MeP6Ns5XejSmmye',
      amount: 25758, // SAR 1
      description: 'order #1324',
      metadata: {'size': '250g'},
      creditCard: CreditCardConfig(saveCard: false, manual: false),
      applePay: ApplePayConfig(
          merchantId: "merchant.sa.aamar.moyasar",
          label: 'Aamar',
          manual: false));

  void onPaymentResult(result) {
    if (result is PaymentResponse) {
      showToast(context, result.status.name);
      switch (result.status) {
        case PaymentStatus.paid:
          // handle success.
          break;
        case PaymentStatus.failed:
          // handle failure.
          break;
        case PaymentStatus.authorized:
          // handle authorized.
          break;
        default:
      }
      return;
    }

    // handle failures.
    if (result is ApiError) {
      showToast(context, result.message);
    }
    if (result is AuthError) {
      showToast(context, result.message);
    }
    if (result is ValidationError) {
      showToast(context, result.message);
    }
    if (result is PaymentCanceledError) {
      showToast(context, 'Payment Canceled');
    }
    if (result is UnprocessableTokenError) {
      showToast(context, 'Unprocessable Token');
    }
    if (result is TimeoutError) {
      showToast(context, 'Timeout Error');
    }
    if (result is NetworkError) {
      showToast(context, 'Network Error');
    }
    if (result is UnspecifiedError) {
      showToast(context, 'Unspecified Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: ListView(
              children: [
                // const CoffeeImage(),
                PaymentMethods(
                  paymentConfig: paymentConfig,
                  onPaymentResult: onPaymentResult,
                ),
              ],
            ),
          ),
        ));
  }
}

void showToast(context, status) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(
      "Status: $status",
      style: const TextStyle(fontSize: 20),
    ),
  ));
}
