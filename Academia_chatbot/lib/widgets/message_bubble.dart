import 'package:flutter/material.dart'; // Importe le package material de Flutter pour les widgets d'interface utilisateur.
import '../models/message.dart'; // Importe le modèle de données Message.

class MessageBubble extends StatelessWidget { // Définit la classe MessageBubble comme un StatelessWidget.
  final Message message; // Le message à afficher dans la bulle.

  const MessageBubble({ // Constructeur de la classe MessageBubble.
    super.key, // Clé du widget.
    required this.message, // Paramètre requis pour le message.
  });

  @override // Annote la méthode build pour remplacer celle de la classe parente.
  Widget build(BuildContext context) { // Construit l'interface utilisateur du widget.
    final isUser = message.isUser; // Vérifie si le message provient de l'utilisateur.
    final bgColor = isUser // Définit la couleur de fond en fonction de l'expéditeur.
        ? Colors.lightBlueAccent.withOpacity(0.85) // Couleur pour l'utilisateur.
        : Colors.grey.shade800; // Couleur pour l'assistant.
    final textColor = isUser ? Colors.white : Colors.white.withOpacity(0.95); // Définit la couleur du texte.

    final radius = const Radius.circular(16); // Définit un rayon pour les coins arrondis.

    return Align( // Aligne la bulle de message.
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft, // Aligne à droite pour l'utilisateur, à gauche sinon.
      child: ConstrainedBox( // Limite la largeur de la bulle.
        constraints: BoxConstraints( // Les contraintes de taille.
          maxWidth: MediaQuery.of(context).size.width * 0.78, // Largeur maximale de 78% de l'écran.
        ),
        child: Container( // Le conteneur de la bulle de message.
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12), // Ajoute une marge externe.
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14), // Ajoute un rembourrage interne.
          decoration: BoxDecoration( // Décoration du conteneur.
            color: bgColor, // Définit la couleur de fond.
            borderRadius: BorderRadius.only( // Définit les coins arrondis de manière sélective.
              topLeft: radius, // Coin supérieur gauche arrondi.
              topRight: radius, // Coin supérieur droit arrondi.
              bottomLeft: isUser ? radius : const Radius.circular(4), // Coin inférieur gauche arrondi différemment.
              bottomRight: isUser ? const Radius.circular(4) : radius, // Coin inférieur droit arrondi différemment.
            ),
          ),
          child: Text( // Le texte du message.
            message.text, // Le contenu textuel du message.
            style: Theme.of(context) // Utilise le thème actuel.
                .textTheme // Accède au thème de texte.
                .bodyMedium // Utilise le style de texte bodyMedium.
                ?.copyWith(color: textColor, height: 1.35), // Personnalise la couleur et la hauteur de ligne.
          ),
        ),
      ),
    );
  }
}
