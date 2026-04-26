import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
     // Définit les couleurs principales pour la cohérence de l'interface utilisateur.
    const violet = Color(0xFF6C63FF);
    const black = Color(0xFF000000);

    return Scaffold(
      backgroundColor: black,
      appBar: AppBar(title: const Text('Se connecter')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centre les éléments verticalement.
              crossAxisAlignment: CrossAxisAlignment.stretch, // Étire les éléments pour qu'ils occupent toute la largeur.
              children: [
                // Icône ou logo de l'application.
                const Icon(
                  Icons.school, // Icône liée à l'éducation.
                  size: 100,
                  color: violet,
                ),
                const SizedBox(height: 16), // Espace vertical.
                // Titre de l'application.
                const Text(
                  'Academia-Chatbot',
                  textAlign: TextAlign.center, // Centre le texte.
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48), // Espace vertical plus grand.
                // Champ de saisie pour l'adresse e-mail.
                
            TextField(
              controller: _email,
              obscureText: false,
                  keyboardType: TextInputType.emailAddress, // Clavier optimisé pour les e-mails.
                  style: const TextStyle(color: Colors.white), // Couleur du texte saisi.
                  decoration: InputDecoration(
                    hintText: 'Adresse e-mail', // Texte indicatif.
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true, // Active le fond coloré.
                    fillColor: const Color(0xFF111111), // Couleur de fond du champ.
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70), // Icône à gauche.
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none, // Aucune bordure visible.
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Espace vertical.
            TextField(
              controller: _pass,
                  obscureText: true, // Masque le texte pour le mot de passe.
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Mot de passe',
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF111111),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32), // Espace vertical.
                // Bouton de connexion.
            FilledButton(
                  onPressed: _loading ? null : _onLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: violet, // Couleur de fond du bouton.
                    foregroundColor: Colors.white, // Couleur du texte.
                    padding: const EdgeInsets.symmetric(vertical: 16), // Rembourrage vertical.
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Coins arrondis.
                    ),
                  ),
                  child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Se connecter'),
                ),
                
                if (_error != null)
                SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ),
                const SizedBox(height: 20,),
                TextButton(
                  onPressed: (){

                  },
                  child: Text("Mot de passe oublié ?"),),
          ],
        ),
      ),
    )
   )
    );
  }

  Future<void> _onLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await authService.login(_email.text.trim(), _pass.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}