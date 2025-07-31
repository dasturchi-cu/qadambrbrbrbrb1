import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qadam_app/app/services/auth_service.dart';
import 'package:qadam_app/app/components/error_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Parolni tiklash',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success message
                if (_isSuccess) 
                  Container(
                    padding: const EdgeInsets.all(15),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 50,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Parolni tiklash bo\'yicha ko\'rsatmalar emailingizga yuborildi',
                          style: const TextStyle(color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Description text
                  Text(
                    'Parolingizni tiklash uchun ro\'yxatdan o\'tgan email manzilingizni kiriting. Biz sizga tiklash bo\'yicha ko\'rsatmalarni yuboramiz.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 30),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Emailni kiriting';
                      }
                      if (!value.contains('@')) {
                        return 'To\'g\'ri email kiriting';
                      }
                      return null;
                    },
                  ),
                  
                  // Error message
                  if (authService.errorMessage != null) ...[
                    const SizedBox(height: 15),
                    AppErrorWidget(
                      message: authService.errorMessage!,
                    ),
                  ],
                ],
                
                const SizedBox(height: 30),
                
                // Reset button
                SizedBox(
                  height: 50,
                  child: _isSuccess
                    ? ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Kirish oynasiga qaytish',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: authService.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  final success = await authService.resetPassword(
                                    _emailController.text.trim(),
                                  );
                                  
                                  if (success && mounted) {
                                    setState(() {
                                      _isSuccess = true;
                                    });
                                  }
                                }
                              },
                        child: authService.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Parolni tiklash',
                                style: TextStyle(fontSize: 16),
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
} 