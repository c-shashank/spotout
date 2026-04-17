import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../bloc/auth_bloc.dart';
import 'otp_verify_screen.dart';
import 'authority_login_screen.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _phoneController = TextEditingController(text: '+91 ');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim().replaceAll(' ', '');
    context.read<AuthBloc>().add(AuthPhoneSendOtp(phone));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthOtpSent) {
          return BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: OtpVerifyScreen(
              verificationId: state.verificationId,
              phoneNumber: state.phoneNumber,
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.appName),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      AppStrings.tagline,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    Text(
                      AppStrings.enterPhone,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText,
                      ),
                      decoration: const InputDecoration(
                        hintText: AppStrings.phoneHint,
                      ),
                      validator: (value) {
                        final cleaned = value?.replaceAll(' ', '') ?? '';
                        if (cleaned.length < 13) return 'Enter a valid 10-digit number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: state is AuthLoading ? null : _sendOtp,
                      child: state is AuthLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(AppStrings.sendOtp),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<AuthBloc>(),
                              child: const AuthorityLoginScreen(),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        AppStrings.authorityPortal,
                        style: GoogleFonts.sourceCodePro(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
