import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:moyasar/moyasar.dart';

class PaymentMethods extends StatelessWidget {
  final PaymentConfig paymentConfig;
  final Function onPaymentResult;

  const PaymentMethods(
      {super.key, required this.paymentConfig, required this.onPaymentResult});
  _onCreditTap() {
    log('Credit Card Tapped');
  }

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
            onCreditTap: _onCreditTap,
            locale: const Localization.ar(),
            config: paymentConfig,
            onPaymentResult: onPaymentResult,
          ),
          if (Platform.isIOS)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ApplePay(
                // onTap: ,

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
