import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_constant.dart';
import 'supabase_service.dart';
import 'glassmorphic_container.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_isLogin) {
          await SupabaseService.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
        } else {
          await SupabaseService.signUp(
            email: _emailController.text,
            password: _passwordController.text,
          );
        }
        // Auth state listener in main.dart will handle navigation
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppConstant.ERROR_COLOR,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider("https://i.postimg.cc/65PgvG1V/bg1.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstant.PADDING_LARGE),
            child: GlassmorphicContainer(
              blur: 15,
              borderRadius: BorderRadius.circular(AppConstant.BORDER_RADIUS_XL),
              child: Padding(
                padding: const EdgeInsets.all(AppConstant.PADDING_LARGE),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Aurix Ai",
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: AppConstant.PADDING_SMALL),
                      Text(
                        "The browser that thinks with you.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: AppConstant.PADDING_LARGE),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) => value!.isEmpty ? 'Enter email' : null,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppConstant.PADDING_MEDIUM),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (value) => value!.length < 6 ? 'Password too short' : null,
                      ),
                      const SizedBox(height: AppConstant.PADDING_LARGE),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstant.PRIMARY_COLOR,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppConstant.PADDING_MEDIUM,
                                  horizontal: 48,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppConstant.BORDER_RADIUS_XL),
                                ),
                              ),
                              child: Text(_isLogin ? 'Login' : 'Sign Up'),
                            ),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(_isLogin
                            ? 'Create an account'
                            : 'Have an account? Login'),
                      ),
                    ],
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