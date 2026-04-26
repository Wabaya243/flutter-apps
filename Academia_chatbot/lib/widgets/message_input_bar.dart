import 'package:flutter/material.dart'; // Importe le package material de Flutter pour les widgets d'interface utilisateur.

class MessageInputBar extends StatelessWidget { // Définit la classe MessageInputBar comme un StatelessWidget.
  final VoidCallback? onNewPressed; // Callback pour le bouton "Nouveau".
  final VoidCallback? onMicPressed; // Callback pour le bouton "Micro".
  final TextEditingController? controller; // Contrôleur pour le champ de texte.
  final ValueChanged<String>? onSubmitted; // Callback pour la soumission du texte.
  final VoidCallback? onSendPressed; // Callback pour le bouton "Envoyer".

  const MessageInputBar({ // Constructeur de la classe MessageInputBar.
    super.key, // Clé du widget.
    this.onNewPressed, // Paramètre pour le callback onNewPressed.
    this.onMicPressed, // Paramètre pour le callback onMicPressed.
    this.controller, // Paramètre pour le contrôleur de texte.
    this.onSubmitted, // Paramètre pour le callback onSubmitted.
    this.onSendPressed, // Paramètre pour le callback onSendPressed.
  });

  @override // Annote la méthode build pour remplacer celle de la classe parente.
  Widget build(BuildContext context) { // Construit l'interface utilisateur du widget.
    final bg = const Color(0xFF0A0A0A); // Définit la couleur de fond.
    final violet = const Color(0xFF6C63FF); // Définit la couleur violette.

    return SafeArea( // Assure que le contenu est visible.
      top: false, // Ne pas appliquer de padding en haut.
      child: Container( // Un conteneur pour la barre de saisie.
        color: bg, // Définit la couleur de fond du conteneur.
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), // Ajoute un rembourrage interne.
        child: Row( // Aligne les widgets enfants horizontalement.
          children: [ // La liste des widgets enfants.
            Container( // Un conteneur pour le bouton "Nouveau".
              decoration: BoxDecoration( // Décoration du conteneur.
                color: violet.withOpacity(0.15), // Couleur de fond avec opacité.
                borderRadius: BorderRadius.circular(12), // Coins arrondis.
              ),
              child: IconButton( // Un bouton avec une icône.
                tooltip: 'New', // Infobulle du bouton.
                icon: const Icon(Icons.add, color: Colors.white), // Icône "plus" blanche.
                onPressed: onNewPressed, // Callback lors de l'appui.
              ),
            ),
            const SizedBox(width: 8), // Un espaceur horizontal.
            Expanded( // Le champ de texte prend l'espace restant.
              child: TextField( // Un champ de saisie de texte.
                controller: controller, // Le contrôleur de texte.
                minLines: 1, // Nombre minimum de lignes.
                maxLines: 4, // Nombre maximum de lignes.
                textInputAction: TextInputAction.send, // Action du clavier "envoyer".
                onSubmitted: onSubmitted, // Callback lors de la soumission.
                decoration: InputDecoration( // Décoration du champ de texte.
                  hintText: 'Demandé a Academia_bot', // Texte indicatif.
                  hintStyle: const TextStyle(color: Colors.white70), // Style du texte indicatif.
                  filled: true, // Le champ est rempli.
                  fillColor: const Color(0xFF111111), // Couleur de remplissage.
                  contentPadding: const EdgeInsets.symmetric( // Rembourrage du contenu.
                    vertical: 12,
                    horizontal: 14,
                  ),
                  suffixIcon: IconButton( // Icône à la fin du champ.
                    tooltip: 'Send', // Infobulle du bouton.
                    icon: const Icon(Icons.send, color: Colors.white70), // Icône "envoyer".
                    onPressed: onSendPressed, // Callback lors de l'appui.
                  ),
                  border: OutlineInputBorder( // Bordure par défaut.
                    borderRadius: BorderRadius.circular(16), // Coins arrondis.
                    borderSide: BorderSide(color: Colors.white10), // Côté de la bordure.
                  ),
                  enabledBorder: OutlineInputBorder( // Bordure quand le champ est activé.
                    borderRadius: BorderRadius.circular(16), // Coins arrondis.
                    borderSide: BorderSide(color: Colors.white10), // Côté de la bordure.
                  ),
                  focusedBorder: OutlineInputBorder( // Bordure quand le champ a le focus.
                    borderRadius: BorderRadius.circular(16), // Coins arrondis.
                    borderSide: BorderSide(color: violet), // Côté de la bordure en violet.
                  ),
                ),
                style: const TextStyle(color: Colors.white), // Style du texte saisi.
              ),
            ),
            const SizedBox(width: 8), // Un espaceur horizontal.
          ],
        ),
      ),
    );
  }
}
