import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/message_bubble.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/conversation_store.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override // Annote la mÃ©thode createState pour remplacer celle de la classe parente.
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // CrÃ©e une clÃ© globale pour le Scaffold.
  final TextEditingController _controller = TextEditingController(); // CrÃ©e un contrÃ´leur pour le champ de texte.
  final ConversationStore _store = ConversationStore(); // CrÃ©e une instance de ConversationStore.
  late final ChatService _chat; // DÃ©clare une variable tardive pour le ChatService.

  List<ConversationMeta> _metas = []; // Initialise une liste vide pour les mÃ©tadonnÃ©es de conversation.
  String? _activeId; // Initialise un ID de conversation actif nullable.
  List<Message> _messages = []; // Initialise une liste vide pour les messages.

  @override
  Widget build(BuildContext context) {
    const black = Color(0xFF000000); // DÃ©finit une constante pour la couleur noire.
    const violet = Color(0xFF6C63FF); // DÃ©finit une constante pour la couleur violette.

    return Scaffold(
      key: _scaffoldKey, // Assigne la clÃ© globale au Scaffold.
      backgroundColor: black, // DÃ©finit la couleur de fond du Scaffold.
      appBar: AppBar( // DÃ©finit la barre d'applications.
        backgroundColor: black, // DÃ©finit la couleur de fond de la barre d'applications.
        centerTitle: true, // Centre le titre dans la barre d'applications.
        leading: IconButton( // Ajoute un widget Ã  gauche dans la barre d'applications.
          icon: const Icon(Icons.menu, color: Colors.white), // DÃ©finit l'icÃ´ne du menu.
          onPressed: () => _scaffoldKey.currentState?.openDrawer(), // Ouvre le tiroir lorsque l'icÃ´ne est pressÃ©e.
          tooltip: 'Menu', // Affiche une infobulle pour l'icÃ´ne.
        ),
        title: OutlinedButton( // DÃ©finit le titre de la barre d'applications comme un bouton.
          onPressed: () {}, // Ne fait rien lorsque le bouton est pressÃ©.
          style: OutlinedButton.styleFrom( // Style du bouton.
            side: const BorderSide(color: violet), // Ajoute une bordure violette.
            foregroundColor: Colors.white, // DÃ©finit la couleur du texte en blanc.
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Ajoute un rembourrage.
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Arrondit les coins du bouton.
          ),
          child: const Text('Get Plus'), // DÃ©finit le texte du bouton.
        ),
      ),
      drawer: AppDrawer( // Ajoute un tiroir de navigation.
        conversations: _metas, // Passe la liste des mÃ©tadonnÃ©es de conversation.
        activeId: _activeId, // Passe l'ID de conversation actif.
        onNewChat: _newChat, // Passe la fonction pour crÃ©er une nouvelle discussion.
        onSelectConversation: (meta) async { // Passe la fonction pour sÃ©lectionner une conversation.
          await _switchTo(meta.id); // Appelle la fonction _switchTo avec l'ID de la conversation.
        },
        onConversationMenu: (meta) async { // Passe la fonction pour afficher le menu de la conversation.
          await _showConversationMenu(meta); // Appelle la fonction _showConversationMenu avec les mÃ©tadonnÃ©es.
        },
      ),
      bottomNavigationBar: MessageInputBar( // Ajoute une barre de saisie de message en bas.
        controller: _controller, // Passe le contrÃ´leur de texte.
        onNewPressed: (){}, // Passe la fonction pour crÃ©er une nouvelle discussion.
        onMicPressed: () {}, // Ne fait rien lorsque le bouton du micro est pressÃ©.
        onSubmitted: (value) => _submit(value), // Appelle la fonction _submit lorsque le texte est soumis.
        onSendPressed: () => _submit(_controller.text), // Appelle la fonction _submit lorsque le bouton d'envoi est pressÃ©.
      ),
      body: SafeArea( // Assure que le contenu est visible.
        child: _messages.isEmpty // VÃ©rifie si la liste des messages est vide.
            ? const Center( // Si elle est vide, affiche un message au centre.
                child: Text( // Widget de texte.
                  'Avec quoi je peux vous aidÃ© ?', // Texte Ã  afficher.
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500), // Style du texte.
                  textAlign: TextAlign.center, // Centre le texte.
                ),
              )
            : ListView.builder( // Sinon, affiche une liste de messages.
                padding: const EdgeInsets.symmetric(vertical: 12), // Ajoute un rembourrage vertical.
                itemCount: _messages.length, // DÃ©finit le nombre d'Ã©lÃ©ments dans la liste.
                itemBuilder: (context, index) => MessageBubble(message: _messages[index]), // Construit chaque bulle de message.
              ),
      ),
    );
  }

  @override
  void initState() { // Initialise l'Ã©tat du widget.
    super.initState(); // Appelle la mÃ©thode initState de la classe parente.
    _chat = ChatService(
      baseUrl: kChatBaseUrl.isNotEmpty ? kChatBaseUrl : 'http://10.0.2.2:8000',
      token: authService.token,
    ); // Initialise le ChatService avec l'URL de base et le token si présent.
    _initConversations(); // Appelle la fonction pour initialiser les conversations.
  }

  Future<void> _initConversations() async { // DÃ©finit une fonction asynchrone pour initialiser les conversations.
    final metas = await _store.loadMetas(); // Charge les mÃ©tadonnÃ©es de conversation.
    final active = await _store.loadActiveId(); // Charge l'ID de conversation actif.
    setState(() { // Met Ã  jour l'Ã©tat du widget.
      _metas = metas; // Met Ã  jour la liste des mÃ©tadonnÃ©es.
      _activeId = active; // Met Ã  jour l'ID de conversation actif.
    });
    if (_activeId != null) { // Si un ID de conversation actif existe.
      _messages = await _store.loadMessages(_activeId!); // Charge les messages pour cet ID.
    }
  }

  Future<void> _newChat() async { // DÃ©finit une fonction asynchrone pour crÃ©er une nouvelle discussion.
    final id = await _store.createConversation(); // CrÃ©e une nouvelle conversation et obtient son ID.
    final metas = await _store.loadMetas(); // Charge les mÃ©tadonnÃ©es de conversation mises Ã  jour.
    setState(() { // Met Ã  jour l'Ã©tat du widget.
      _metas = metas; // Met Ã  jour la liste des mÃ©tadonnÃ©es.
      _activeId = id; // DÃ©finit le nouvel ID comme actif.
      _messages = []; // Efface la liste des messages.
    });
    if (Navigator.canPop(context)) Navigator.of(context).maybePop(); // Ferme le tiroir si possible.
  }

  Future<void> _switchTo(String id) async { // DÃ©finit une fonction asynchrone pour changer de conversation.
    final msgs = await _store.loadMessages(id); // Charge les messages pour l'ID donnÃ©.
    await _store.saveActiveId(id); // Enregistre l'ID comme actif.
    setState(() { // Met Ã  jour l'Ã©tat du widget.
      _activeId = id; // Met Ã  jour l'ID de conversation actif.
      _messages = msgs; // Met Ã  jour la liste des messages.
    });
    if (Navigator.canPop(context)) Navigator.of(context).maybePop(); // Ferme le tiroir si possible.
  }

  Future<void> _submit(String value) async { // DÃ©finit une fonction asynchrone pour soumettre un message.
    final text = value.trim(); // Supprime les espaces au dÃ©but et Ã  la fin du texte.
    if (text.isEmpty) return; // Si le texte est vide, ne fait rien.
    _controller.clear(); // Efface le champ de texte.
    if (_activeId == null) { // Si aucune conversation n'est active.
      await _newChat(); // CrÃ©e une nouvelle discussion.
    }
    final id = _activeId!; // Obtient l'ID de conversation actif.

    // Ajoute le message utilisateur
    final user = Message(sender: MessageSender.user, text: text, timestamp: DateTime.now()); // CrÃ©e un objet Message pour l'utilisateur.
    setState(() => _messages.add(user)); // Ajoute le message Ã  la liste et met Ã  jour l'interface utilisateur.
    await _store.saveMessages(id, _messages); // Enregistre les messages dans le stockage.

    // Ajoute un message assistant vide pour le streaming
    final assistantIndex = _messages.length; // Obtient l'index pour le message de l'assistant.
    setState(() => _messages.add(Message(sender: MessageSender.assistant, text: '', timestamp: DateTime.now()))); // Ajoute un message d'assistant vide.

    // Stream depuis l'API
    try { // Bloc try pour la gestion des erreurs.
      final isFirstInConv = _messages.where((m) => m.isUser || !m.isUser).length <= 1; // just added user // VÃ©rifie si c'est le premier message de la conversation.
      await for (final chunk in _chat.replyStream( // ItÃ¨re sur le flux de rÃ©ponse du chat.
        text, // Le texte du message de l'utilisateur.
        _messages, // La liste des messages actuels.
        sessionId: _activeId, // L'ID de la session.
        reset: isFirstInConv, // Indique s'il faut rÃ©initialiser la conversation.
      )) {
        setState(() { // Met Ã  jour l'Ã©tat du widget.
          final prev = _messages[assistantIndex].text; // Obtient le texte prÃ©cÃ©dent du message de l'assistant.
          _messages[assistantIndex] = Message( // Met Ã  jour le message de l'assistant.
            sender: MessageSender.assistant, // L'expÃ©diteur est l'assistant.
            text: '$prev$chunk', // Ajoute le nouveau morceau de texte.
            timestamp: DateTime.now(), // Met Ã  jour l'horodatage.
          );
        });
      }
      await _store.saveMessages(id, _messages); // Enregistre les messages mis Ã  jour.
      // Met Ã  jour l'ordre et la date de la conversation
      await _store.archiveConversation(id); // utilise archive pour mettre Ã  jour updatedAt // Archive la conversation pour mettre Ã  jour sa date.
      final metas = await _store.loadMetas(); // Charge les mÃ©tadonnÃ©es de conversation mises Ã  jour.
      setState(() => _metas = metas); // Met Ã  jour la liste des mÃ©tadonnÃ©es dans l'Ã©tat.
      // Titre depuis le 1er message si conversation sans titre
      final idx = _metas.indexWhere((m) => m.id == id); // Trouve l'index de la conversation actuelle.
      if (idx != -1 && (_metas[idx].title == 'Nouvelle conversation' || _metas[idx].title.isEmpty)) { // Si la conversation a un titre par dÃ©faut.
        final newTitle = text.length > 32 ? text.substring(0, 32) : text; // CrÃ©e un nouveau titre Ã  partir du message.
        await _store.renameConversation(id, newTitle); // Renomme la conversation dans le stockage.
        setState(() => _metas[idx] = _metas[idx].copyWith(title: newTitle)); // Met Ã  jour le titre dans l'Ã©tat.
      }
    } catch (e) { // Bloc catch pour la gestion des erreurs.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'))); // Affiche une snackbar en cas d'erreur.
    }
  }

  Future<void> _showConversationMenu(ConversationMeta meta) async { // DÃ©finit une fonction asynchrone pour afficher le menu de la conversation.
    if (!mounted) return; // Si le widget n'est pas montÃ©, ne fait rien.
    final choice = await showModalBottomSheet<String>( // Affiche une feuille modale en bas.
      context: context, // Le contexte de construction.
      builder: (ctx) => SafeArea( // Assure que le contenu est visible.
        child: Column( // Affiche les options dans une colonne.
          mainAxisSize: MainAxisSize.min, // La colonne prend le moins de place possible.
          children: [ // La liste des options.
            ListTile( // Option pour renommer.
              leading: const Icon(Icons.edit), // IcÃ´ne de modification.
              title: const Text('Renommer'), // Texte de l'option.
              onTap: () => Navigator.pop(ctx, 'rename'), // Retourne 'rename' lors de l'appui.
            ),
            ListTile( // Option pour archiver.
              leading: const Icon(Icons.archive_outlined), // IcÃ´ne d'archive.
              title: const Text('Archiver'), // Texte de l'option.
              onTap: () => Navigator.pop(ctx, 'archive'), // Retourne 'archive' lors de l'appui.
            ),
            const Divider(height: 1), // Une ligne de sÃ©paration.
            ListTile( // Option pour supprimer.
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent), // IcÃ´ne de suppression.
              title: const Text('Supprimer la conversation'), // Texte de l'option.
              textColor: Colors.redAccent, // Couleur du texte.
              iconColor: Colors.redAccent, // Couleur de l'icÃ´ne.
              onTap: () => Navigator.pop(ctx, 'delete'), // Retourne 'delete' lors de l'appui.
            ),
          ],
        ),
      ),
    );
    if (choice == null) return; // Si aucun choix n'est fait, ne fait rien.
    switch (choice) { // ExÃ©cute une action en fonction du choix.
      case 'clear': // Si le choix est 'clear'.
        await _store.clearMemory(meta.id); // Efface la mÃ©moire de la conversation.
        if (_activeId == meta.id) { // Si la conversation effacÃ©e est active.
          setState(() => _messages.clear()); // Efface les messages de l'interface utilisateur.
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MÃ©moire supprimÃ©e'))); // Affiche une confirmation.
        break;
      case 'rename': // Si le choix est 'rename'.
        final controller = TextEditingController(text: meta.title); // CrÃ©e un contrÃ´leur avec le titre actuel.
        final newTitle = await showDialog<String>( // Affiche une boÃ®te de dialogue pour renommer.
          context: context, // Le contexte de construction.
          builder: (ctx) => AlertDialog( // La boÃ®te de dialogue.
            title: const Text('Renommer la conversation'), // Le titre de la boÃ®te de dialogue.
            content: TextField(controller: controller, autofocus: true), // Le champ de texte pour le nouveau titre.
            actions: [ // Les boutons d'action.
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')), // Bouton pour annuler.
              FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('OK')), // Bouton pour confirmer.
            ],
          ),
        );
        if (newTitle != null && newTitle.trim().isNotEmpty) { // Si un nouveau titre a Ã©tÃ© fourni.
          await _store.renameConversation(meta.id, newTitle.trim()); // Renomme la conversation dans le stockage.
          final idx = _metas.indexWhere((m) => m.id == meta.id); // Trouve l'index de la conversation.
          if (idx != -1) setState(() => _metas[idx] = _metas[idx].copyWith(title: newTitle.trim())); // Met Ã  jour le titre dans l'Ã©tat.
        }
        break;
      case 'archive': // Si le choix est 'archive'.
        await _store.archiveConversation(meta.id); // Archive la conversation.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversation archivÃ©e'))); // Affiche une confirmation.
        break;
      case 'delete': // Si le choix est 'delete'.
        await _store.deleteConversation(meta.id); // Supprime la conversation.
        final metas = await _store.loadMetas(); // Recharge les mÃ©tadonnÃ©es.
        final active = await _store.loadActiveId(); // Recharge l'ID actif.
        setState(() { // Met Ã  jour l'Ã©tat.
          _metas = metas; // Met Ã  jour les mÃ©tadonnÃ©es.
          _activeId = (active == null || active.isEmpty) ? null : active; // Met Ã  jour l'ID actif.
          if (_activeId == null) _messages.clear(); // Efface les messages si aucune conversation n'est active.
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversation supprimÃ©e'))); // Affiche une confirmation.
        break;
    }
  }
}

