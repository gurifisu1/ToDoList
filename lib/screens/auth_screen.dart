import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(supabaseServiceProvider);
      if (_isLogin) {
        await service.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await service.signUp(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.glassWhite,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App icon
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            size: 40,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _isLogin ? 'ログイン' : 'アカウント作成',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin
                              ? 'メールとパスワードでログイン'
                              : '新しいアカウントを作成',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'メールアドレス',
                            prefixIcon: Icon(Icons.email_outlined,
                                color: AppTheme.textSecondary),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'メールアドレスを入力してください';
                            }
                            if (!value.contains('@')) {
                              return '有効なメールアドレスを入力してください';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'パスワード',
                            prefixIcon: Icon(Icons.lock_outline,
                                color: AppTheme.textSecondary),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'パスワードを入力してください';
                            }
                            if (value.length < 6) {
                              return 'パスワードは6文字以上にしてください';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: AppTheme.accentRed,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'ログイン' : '登録',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Toggle login/signup
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _error = null;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'アカウントをお持ちでない方はこちら'
                                : 'すでにアカウントをお持ちの方はこちら',
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
