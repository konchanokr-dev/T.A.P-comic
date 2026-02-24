import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/features/auth/main_shell.dart';  
import 'register.dart';
import '../../data/repos/user_repo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _userRepo = UserRepo();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Center(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.asset('assets/icon/fakelogo.png'),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'login',
                        style: TextStyle(color: Colors.white, fontSize: 32 ,fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                  TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Username",
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF484848),
                         focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color(0xFF282828) ,
        width: 6,),),
                           border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),

                          borderSide: BorderSide.none, ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF282828) ,width: 8,),
                                borderRadius: BorderRadius.circular(16),
                             
                             ),
                             
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter username';
                          }
                          return null;
                        },
                      ),
                 
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                                                obscureText: true,

                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF484848),
                         focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color(0xFF282828) ,
        width: 6,),),
                           border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),

                          borderSide: BorderSide.none, ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF282828) ,width: 8,),
                                borderRadius: BorderRadius.circular(16),
                             
                             ),
                             
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: (){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const Register()),
                              );
                            },
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                  color: Color(0xFF3642E9)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
 
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 52, 52, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: _handleLogin,
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Color.fromARGB(255, 221, 221, 221),
                            fontSize: 24,
                          ),
                        ),
                      ),
                       ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 52, 52, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  },
                        child: const Text(
                          'skip login for test',
                          style: TextStyle(
                            color: Color.fromARGB(255, 221, 221, 221),
                            fontSize: 24,
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
    );
  }

 Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    final user = await _userRepo.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("userUuid", user.uuid);
      await prefs.setString("username", user.name);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid username or password")),
      );
    }
  } catch (e) {
    print("LOGIN ERROR: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Something went wrong")),
    );
  }
}}