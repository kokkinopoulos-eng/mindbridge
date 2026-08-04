import 'package:flutter/material.dart';

class MbTextField extends StatelessWidget {
  const MbTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffix,
    this.onFieldSubmitted,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onFieldSubmitted;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF52514E),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller:      controller,
            validator:       validator,
            keyboardType:    keyboardType,
            textInputAction: textInputAction,
            obscureText:     obscureText,
            onFieldSubmitted: onFieldSubmitted,
            maxLines:        obscureText ? 1 : maxLines,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffix,
            ),
          ),
        ],
      );
}
