import 'package:flutter/material.dart'; // Importe le package material de Flutter pour les widgets d'interface utilisateur.

import '../models/conversation.dart'; // Importe le modèle de données Conversation.

class AppDrawer extends StatelessWidget { // Définit la classe AppDrawer comme un StatelessWidget.
  final void Function(String label)? onTapLabel; // Callback pour l'appui sur une étiquette.
  final List<ConversationMeta> conversations; // La liste des métadonnées de conversation.
  final String? activeId; // L'ID de la conversation active.
  final VoidCallback? onNewChat; // Callback pour démarrer une nouvelle discussion.
  final void Function(ConversationMeta meta)? onSelectConversation; // Callback pour sélectionner une conversation.
  final void Function(ConversationMeta meta)? onConversationMenu; // Callback pour le menu de la conversation.

  const AppDrawer({ // Constructeur de la classe AppDrawer.
    super.key, // Clé du widget.
    this.onTapLabel, // Paramètre pour le callback onTapLabel.
    required this.conversations, // Paramètre requis pour la liste des conversations.
    this.activeId, // Paramètre pour l'ID actif.
    this.onNewChat, // Paramètre pour le callback onNewChat.
    this.onSelectConversation, // Paramètre pour le callback onSelectConversation.
    this.onConversationMenu, // Paramètre pour le callback onConversationMenu.
  });

  void _handleTap(BuildContext context, String label) { // Gère l'appui sur une étiquette.
    Navigator.of(context).maybePop(); // Ferme le tiroir si possible.
    final snack = SnackBar(content: Text(label)); // Crée une SnackBar avec l'étiquette.
    ScaffoldMessenger.of(context).showSnackBar(snack); // Affiche la SnackBar.
    onTapLabel?.call(label); // Appelle le callback onTapLabel.
  }

  @override // Annote la méthode build pour remplacer celle de la classe parente.
  Widget build(BuildContext context) { // Construit l'interface utilisateur du widget.
    final violet = const Color(0xFF6C63FF); // Définit une constante pour la couleur violette.
    return Drawer( // Retourne un widget Drawer.
      child: SafeArea( // Assure que le contenu est visible.
        child: Column( // Aligne les widgets enfants verticalement.
          crossAxisAlignment: CrossAxisAlignment.stretch, // Étire les enfants pour remplir l'axe transversal.
          children: [ // La liste des widgets enfants.
            Padding( // Ajoute un rembourrage autour du champ de recherche.
              padding: const EdgeInsets.all(12.0), // Rembourrage sur tous les côtés.
              child: TextField( // Un champ de saisie de texte pour la recherche.
                decoration: InputDecoration( // Décoration du champ de texte.
                  hintText: 'Search', // Texte indicatif.
                  prefixIcon: const Icon(Icons.search), // Icône de recherche au début.
                  filled: true, // Le champ est rempli.
                  fillColor: const Color(0xFF111111), // Couleur de remplissage.
                  border: OutlineInputBorder( // Bordure par défaut.
                    borderRadius: BorderRadius.circular(12), // Coins arrondis.
                    borderSide: const BorderSide(color: Colors.white12), // Côté de la bordure.
                  ),
                  enabledBorder: OutlineInputBorder( // Bordure quand le champ est activé.
                    borderRadius: BorderRadius.circular(12), // Coins arrondis.
                    borderSide: const BorderSide(color: Colors.white12), // Côté de la bordure.
                  ),
                ),
                style: const TextStyle(color: Colors.white), // Style du texte saisi.
              ),
            ),
            Padding( // Ajoute un rembourrage autour du bouton "New chat".
              padding: const EdgeInsets.symmetric(horizontal: 12), // Rembourrage horizontal.
              child: FilledButton.icon( // Un bouton rempli avec une icône.
                onPressed: onNewChat, // Callback lors de l'appui.
                icon: const Icon(Icons.add, color: Colors.white), // Icône "plus" blanche.
                label: const Text('New chat'), // Texte du bouton.
                style: FilledButton.styleFrom( // Style du bouton.
                  backgroundColor: violet, // Couleur de fond violette.
                  foregroundColor: Colors.white, // Couleur du texte et de l'icône en blanc.
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Coins arrondis.
                ),
              ),
            ),
            const SizedBox(height: 8), // Un espaceur vertical.
            Expanded( // La liste prend l'espace restant.
              child: ListView( // Une liste déroulante.
                children: [ // Les enfants de la liste.
                  // Liste des conversations créées dynamiquement
                  ...conversations.map((c) => ListTile( // Itère sur les conversations pour créer des ListTile.
                        leading: const Icon(Icons.chat_bubble_outline, color: Colors.white), // Icône de bulle de discussion.
                        title: Text( // Le titre de la conversation.
                          c.title.isEmpty ? 'Sans titre' : c.title, // Affiche "Sans titre" si le titre est vide.
                          style: TextStyle( // Style du titre.
                            color: Colors.white, // Couleur du texte en blanc.
                            fontWeight: c.id == activeId ? FontWeight.bold : FontWeight.normal, // Met en gras si la conversation est active.
                          ),
                        ),
                        trailing: IconButton( // Un bouton à la fin de la tuile.
                          tooltip: 'Actions', // Infobulle du bouton.
                          icon: const Icon(Icons.more_vert, color: Colors.white70), // Icône "plus vertical".
                          onPressed: () => onConversationMenu?.call(c), // Appelle le callback du menu lors de l'appui.
                        ),
                        onTap: () => onSelectConversation?.call(c), // Appelle le callback de sélection lors de l'appui.
                      )),
                  const Divider(height: 24), // Une ligne de séparation avec de l'espace.
                  _item(context, Icons.menu_book_outlined, 'Library'), // Un élément de menu personnalisé.
                  _item(context, Icons.auto_awesome_outlined, 'ChatBot_Academia'), // Un autre élément de menu personnalisé.
                ],
              ),
            ),
            const Divider(height: 1), // Une ligne de séparation fine.
            // Bouton compte / Settings
            Padding( // Ajoute un rembourrage autour du bouton "Compte / Paramètres".
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12), // Rembourrage personnalisé.
              child: OutlinedButton( // Un bouton avec une bordure.
                onPressed: () { // Action lors de l'appui.
                  Navigator.of(context).maybePop(); // Ferme le tiroir.
                  Navigator.of(context).pushNamed('/settings'); // Navigue vers la page des paramètres.
                },
                style: OutlinedButton.styleFrom( // Style du bouton.
                  foregroundColor: Colors.white, // Couleur du texte en blanc.
                  side: const BorderSide(color: Colors.white24), // Bordure blanche semi-transparente.
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Coins arrondis.
                ),
                child: const Align( // Aligne le texte à gauche.
                  alignment: Alignment.centerLeft, // Alignement à gauche.
                  child: Text('Compte / Paramètres'), // Texte du bouton.
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label) { // Méthode pour créer un élément de menu.
    return ListTile( // Retourne une tuile de liste.
      leading: Icon(icon, color: Colors.white), // L'icône de l'élément.
      title: Text(label, style: const TextStyle(color: Colors.white)), // Le texte de l'élément.
      onTap: () => _handleTap(context, label), // Action lors de l'appui.
    );
  }
}
