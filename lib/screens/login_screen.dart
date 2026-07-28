import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  String _errorMessage = '';

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || username.length < 3) {
      setState(() => _errorMessage = 'Tên đăng nhập phải có ít nhất 3 ký tự');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu phải từ 6 ký tự trở lên');
      return;
    }

    setState(() {
      _errorMessage = '';
    });

    // Thủ thuật nối đuôi ảo để qua mặt Firebase
    final fakeEmail = "$username@studentapp.ctu";

    try {
      if (_isLogin) {
        // 1. Gửi yêu cầu ĐĂNG NHẬP lên máy chủ Firebase
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: fakeEmail,
          password: password,
        );
        print("ĐĂNG NHẬP THÀNH CÔNG! Chuyển vào màn hình chính...");

        // 2. Kỹ thuật an toàn của Flutter: Đợi mạng xong phải kiểm tra xem màn hình còn mở không
        if (!mounted) return;

        // 3. Chuyển sang màn hình chính và xóa màn hình Login khỏi lịch sử
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // Thay "HomeScreen" bằng đúng tên class màn hình chính của bạn nhé
            builder: (context) => const HomeScreen(),
          ),
        );

      } else {
        // Gửi yêu cầu ĐĂNG KÝ lên máy chủ Firebase
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: fakeEmail,
          password: password,
        );
        print("ĐĂNG KÝ THÀNH CÔNG! Chuyển vào màn hình chính...");

        // Đăng ký xong thì tự động chuyển về giao diện Đăng nhập
        setState(() {
          _isLogin = true;
          _errorMessage = 'Đăng ký thành công! Vui lòng đăng nhập lại.';
        });
      }
    } on FirebaseAuthException catch (e) {
      // Bắt lỗi từ Firebase (Sai pass, trùng tên...)
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          _errorMessage = 'Sai tên đăng nhập hoặc mật khẩu!';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'Tên đăng nhập này đã có người sử dụng!';
        } else {
          _errorMessage = 'Lỗi kết nối máy chủ: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi không xác định!';
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- PHẦN VẼ GIAO DIỆN NẰM Ở ĐÂY ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Icon(Icons.school, size: 80, color: Theme.of(context).primaryColor),
              const SizedBox(height: 24),
              Text(
                _isLogin ? 'Chào mừng trở lại!' : 'Đăng ký tài khoản',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Đăng nhập để quản lý lịch học' : 'Đăng ký tài khoản để đồng bộ dữ liệu',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Tên đăng nhập',
                  hintText: 'VD: nguyenvana123',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit, // KHI BẤM NÚT NÀY, HÀM _submit Ở TRÊN SẼ CHẠY
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isLogin ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ TÀI KHOẢN',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _errorMessage = '';
                  });
                },
                child: Text(_isLogin
                    ? 'Chưa có tài khoản? Đăng ký ngay'
                    : 'Đã có tài khoản? Đăng nhập'),
              )
            ],
          ),
        ),
      ),
    );
  }
}