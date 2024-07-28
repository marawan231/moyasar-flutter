import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moyasar/moyasar.dart';
import 'package:moyasar/src/utils/card_utils.dart';
import 'package:moyasar/src/utils/input_formatters.dart';
import 'package:moyasar/src/widgets/network_icons.dart';
import 'package:moyasar/src/widgets/three_d_s_webview.dart';

/// The widget that shows the Credit Card form and manages the 3DS step.
class CreditCard extends StatefulWidget {
  CreditCard(
      {super.key,
      required this.config,
      required this.onPaymentResult,
      this.locale = const Localization.en(),
      this.conditionsWidget})
      : textDirection =
            locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  final Function onPaymentResult;
  final PaymentConfig config;
  final Localization locale;
  final TextDirection textDirection;
  final Widget? conditionsWidget;

  @override
  State<CreditCard> createState() => _CreditCardState();
}

class _CreditCardState extends State<CreditCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _cardData = CardFormModel();

  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  bool _isSubmitting = false;

  bool _tokenizeCard = false;

  bool _manualPayment = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _tokenizeCard = widget.config.creditCard?.saveCard ?? false;
      _manualPayment = widget.config.creditCard?.manual ?? false;
    });
  }

  void _saveForm() async {
    closeKeyboard();

    bool isValidForm =
        _formKey.currentState != null && _formKey.currentState!.validate();

    if (!isValidForm) {
      setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    _formKey.currentState?.save();

    final source = CardPaymentRequestSource(
        creditCardData: _cardData,
        tokenizeCard: _tokenizeCard,
        manualPayment: _manualPayment);
    final paymentRequest = PaymentRequest(widget.config, source);

    setState(() => _isSubmitting = true);

    final result = await Moyasar.pay(
        apiKey: widget.config.publishableApiKey,
        paymentRequest: paymentRequest);

    setState(() => _isSubmitting = false);

    if (result is! PaymentResponse ||
        result.status != PaymentStatus.initiated) {
      widget.onPaymentResult(result);
      return;
    }

    final String transactionUrl =
        (result.source as CardPaymentResponseSource).transactionUrl;

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            maintainState: false,
            builder: (context) => ThreeDSWebView(
                transactionUrl: transactionUrl,
                on3dsDone: (String status, String message) async {
                  if (status == PaymentStatus.paid.name) {
                    result.status = PaymentStatus.paid;
                  } else if (status == PaymentStatus.authorized.name) {
                    result.status = PaymentStatus.authorized;
                  } else {
                    result.status = PaymentStatus.failed;
                    (result.source as CardPaymentResponseSource).message =
                        message;
                  }
                  Navigator.pop(context);
                  widget.onPaymentResult(result);
                })),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: _autoValidateMode,
      key: _formKey,
      child: Column(
        children: [
          CardFormField(
              headlineText: 'الاسم على البطاقة',
              inputDecoration: buildInputDecoration(
                hintText: widget.locale.nameOnCard,
                hintTextDirection: widget.textDirection,
                addNetworkIcons: false,
              ),
              keyboardType: TextInputType.text,
              validator: (String? input) =>
                  CardUtils.validateName(input, widget.locale),
              onSaved: (value) => _cardData.name = value ?? '',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z. ]')),
              ]),
          const SizedBox(height: 8),
          CardFormField(
            headlineText: 'رجاء إدخال رقم البطاقة',
            inputDecoration: buildInputDecoration(
                hintText: widget.locale.cardNumber,
                hintTextDirection: widget.textDirection,
                addNetworkIcons: false),
            validator: (String? input) =>
                CardUtils.validateCardNum(input, widget.locale),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              CardNumberInputFormatter(),
            ],
            onSaved: (value) =>
                _cardData.number = CardUtils.getCleanedNumber(value!),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CardFormField(
                  headlineText: 'تاريخ الصلاحية',
                  inputDecoration: buildInputDecoration(
                    hintText: widget.locale.expiry,
                    hintTextDirection: widget.textDirection,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    CardMonthInputFormatter(),
                  ],
                  validator: (String? input) =>
                      CardUtils.validateDate(input, widget.locale),
                  onSaved: (value) {
                    List<String> expireDate = CardUtils.getExpiryDate(value!);
                    _cardData.month = expireDate.first;
                    _cardData.year = expireDate[1];
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CardFormField(
                  headlineText: 'CVV',
                  inputDecoration: buildInputDecoration(
                    hintText: widget.locale.cvc,
                    hintTextDirection: widget.textDirection,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (String? input) =>
                      CardUtils.validateCVC(input, widget.locale),
                  onSaved: (value) => _cardData.cvc = value ?? '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          widget.conditionsWidget ?? const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF335FFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isSubmitting ? () {} : _saveForm,
                child: _isSubmitting
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : Text(
                        "دفع رسوم الخدمة  ",
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textDirection: widget.textDirection,
                      ),
              ),
            ),
          ),
          //TODO to be implemented later on the next version of the package with the save card feature
          // SaveCardNotice(tokenizeCard: _tokenizeCard, locale: widget.locale)
        ],
      ),
    );
  }
}

class SaveCardNotice extends StatelessWidget {
  const SaveCardNotice(
      {super.key, required this.tokenizeCard, required this.locale});

  final bool tokenizeCard;
  final Localization locale;

  @override
  Widget build(BuildContext context) {
    return tokenizeCard
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.info,
                  color: blueColor,
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 5),
                ),
                Text(
                  locale.saveCardNotice,
                  style: TextStyle(color: blueColor),
                ),
              ],
            ))
        : const SizedBox.shrink();
  }
}

class CardFormField extends StatelessWidget {
  final void Function(String?)? onSaved;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration? inputDecoration;
  final String? headlineText;

  const CardFormField({
    super.key,
    required this.onSaved,
    this.validator,
    this.inputDecoration,
    this.keyboardType = TextInputType.number,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.headlineText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headlineText ?? '',
          style: const TextStyle(
            color: Color.fromARGB(255, 13, 13, 13),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
              top: 6, bottom: 0, start: 0, end: 0),
          child: TextFormField(
              // st
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              decoration: inputDecoration,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'IBMPlexSansArabic',
              ),
              validator: validator,
              onSaved: onSaved,
              inputFormatters: inputFormatters),
        ),
      ],
    );
  }
}

String showAmount(int amount, String currency, Localization locale) {
  final formattedAmount = (amount / 100).toStringAsFixed(2);
  return '${locale.pay} $currency $formattedAmount';
}

InputDecoration buildInputDecoration(
    {required String hintText,
    required TextDirection hintTextDirection,
    bool addNetworkIcons = false}) {
  /*
        isDense: true,
        filled: true,
        fillColor: ColorManager.white,
        hintStyle: getMediumStyle(
          color: ColorManager.darkGrey,
          fontSize: 18.sp,
        ),

        // contentPadding: EdgeInsets.symmetric(
        //     vertical: AppPadding.pH16, horizontal: AppPadding.pH16),
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: ColorManager.grey, width: 1),
            borderRadius: BorderRadius.circular(AppBorderRadius.r8)),
        focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: ColorManager.primary, width: 1),
            borderRadius: BorderRadius.circular(AppBorderRadius.r8)),
        disabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: ColorManager.grey, width: 1),
            borderRadius: BorderRadius.circular(AppBorderRadius.r8)),
        errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: ColorManager.error, width: 1),
            borderRadius: BorderRadius.circular(AppBorderRadius.r8)),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: ColorManager.error, width: 1),
          borderRadius: BorderRadius.circular(AppBorderRadius.r8),
        ),
       */
  return InputDecoration(
    suffixIcon: addNetworkIcons ? const NetworkIcons() : null,
    hintText: hintText,
    hintStyle: const TextStyle(
        color: Color(0xFF7E878E),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'IBMPlexSansArabic'),
    hintTextDirection: hintTextDirection,
    focusedErrorBorder: defaultErrorBorder,
    enabledBorder: defaultEnabledBorder,
    focusedBorder: defaultFocusedBorder,
    disabledBorder: defaultEnabledBorder,
    errorBorder: defaultErrorBorder,
    contentPadding: const EdgeInsetsDirectional.only(
        start: 16, end: 16, top: 10, bottom: 10),
  );
}

void closeKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

BorderRadius defaultBorderRadius = const BorderRadius.all(Radius.circular(8));

OutlineInputBorder defaultEnabledBorder = OutlineInputBorder(
    borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
    borderRadius: defaultBorderRadius);

OutlineInputBorder defaultFocusedBorder = OutlineInputBorder(
    borderSide: const BorderSide(color: Color(0xFF335FFF)),
    borderRadius: defaultBorderRadius);

OutlineInputBorder defaultErrorBorder = OutlineInputBorder(
    borderSide: const BorderSide(color: Color(0xFFF33838)),
    borderRadius: defaultBorderRadius);

Color blueColor = Colors.blue[700]!;
