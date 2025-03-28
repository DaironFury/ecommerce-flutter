import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> logIn(String email, String password) async{

    try{
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    }on FirebaseAuthException{
      print("Error intentando iniciar la sesión");
      return null;
    }

  }

  Future<UserCredential?> register(String email, String password) async{
    try{
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    }on FirebaseAuthException{
      print("Error intentando realizar el registro");
      return null;
    }
  }

  
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /*
  Future<String?> getJwtToken() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        String? token = await user.getIdToken();
        return token;
      } catch (e) {
        print("Error obteniendo el token: $e");
        return null;
      }
    }
    return null;
  }
  */

}