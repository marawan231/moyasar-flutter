import 'dart:io';

import 'package:flutter/material.dart';
import 'package:moyasar/moyasar.dart';

class PaymentMethods extends StatelessWidget {
  final PaymentConfig paymentConfig;
  final Function onPaymentResult;

  const PaymentMethods(
      {super.key, required this.paymentConfig, required this.onPaymentResult});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildHeadline(),
          CreditCard(
            locale: const Localization.ar(),
            config: paymentConfig,
            onPaymentResult: onPaymentResult,
          ),
          if (Platform.isIOS)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ApplePay(
                
                // buttonStyle:  ApplePayButtonStyle.black,
                config: paymentConfig,
                onPaymentResult: onPaymentResult,
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  _buildHeadline() {
    return Text(
      'معلومات الدفع',
      style: TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'IBMPlexSansArabic',
      ),
    );
  }
}
