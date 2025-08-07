import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wordstory/data/models/center.dart';
// import 'package:wordstory/util/util_dialog.dart';
import '../providers/app_auth_provider.dart';

/// Login/registration page.  Users can either sign in with their
/// email/password, register a new account, or authenticate via
/// Google.  A simple segmented control toggles between sign in and
/// sign up modes.  In either mode, form validation ensures the
/// required fields are filled before submission.
class LoginScreen extends StatefulWidget {
  final String? initialCenterCode;
  final Role? role;
  const LoginScreen({super.key, this.initialCenterCode, this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSignUp = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _signUpAsCenter = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _submit(AppAuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _displayNameController.text.trim();
    try {
      if (isSignUp) {
        await auth.signUpWithEmail(context, email, password, displayName, role: widget.role);
      } else {
        await auth.signInWithEmail(context, email, password);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initialCenterCode == null ? 'WordStory' : 'Word Story',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Sign In'),
                      selected: !isSignUp,
                      onSelected: (val) {
                        setState(() {
                          isSignUp = !val;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Sign Up'),
                      selected: isSignUp,
                      onSelected: (val) {
                        setState(() {
                          isSignUp = val;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                if (isSignUp) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sign up as Center'),
                    value: _signUpAsCenter,
                    onChanged: (val) {
                      setState(() {
                        _signUpAsCenter = val ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : () => _submit(auth),
                  child: Text(isSignUp ? 'Register' : 'Sign In'),
                ),
                const SizedBox(height: 12),
                if (!_signUpAsCenter || !isSignUp)
                  OutlinedButton.icon(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            try {
                              await auth.signInWithGoogle(context, isSignUp,
                                  centerCode: widget.initialCenterCode, role: widget.role);
                            } on Exception catch (e) {
                              print(e.toString());
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(content: Text('Error: ${e.toString()}')),
                              // );
                            }
                          },
                    icon: const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                  ),
                if (auth.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
