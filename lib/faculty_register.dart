import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FacultyRegisterPage extends StatefulWidget {
  const FacultyRegisterPage({super.key});

  @override
  State<FacultyRegisterPage> createState() => _FacultyRegisterPageState();
}

class _FacultyRegisterPageState extends State<FacultyRegisterPage> {
  final _nameController = TextEditingController();
  final _deptController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  File? _image;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // compression
    );
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _registerFaculty() async {
    if (_image == null) {
      _showMsg("Please select photo");
      return;
    }

    setState(() => _loading = true);

    try {
      // 1️⃣ Create Auth account
      UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = cred.user!.uid;

      // 2️⃣ Upload photo to Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('faculty_photos')
          .child('$uid.jpg');

      await ref.putFile(_image!);
      String photoUrl = await ref.getDownloadURL();

      // 3️⃣ Save data to Firestore
      await FirebaseFirestore.instance
          .collection('faculties')
          .doc(uid)
          .set({
        'name': _nameController.text.trim(),
        'department': _deptController.text.trim(),
        'email': _emailController.text.trim(),
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showMsg("Registration successful. Please login");
      Navigator.pop(context); // back to login
    } catch (e) {
      _showMsg(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Faculty Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? const Icon(Icons.camera_alt, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              _field(_nameController, "Name"),
              _field(_deptController, "Department"),
              _field(_emailController, "Email"),
              _field(_passwordController, "Password", obscure: true),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _registerFaculty,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
