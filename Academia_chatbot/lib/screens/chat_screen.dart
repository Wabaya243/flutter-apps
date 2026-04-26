import 'dart:async'; // Importe les fonctionnalitÃ©s asynchrones comme Stream.
import 'dart:convert'; // Importe les dÃ©codeurs et encodeurs JSON.
import 'dart:io' show Platform; // Importe la classe Platform pour vÃ©rifier le systÃ¨me d'exploitation.
import '../config.dart'; // Importe le fichier de configuration de l'application.

import 'package:flutter/material.dart'; // Importe le package principal de Flutter pour l'interface utilisateur.
import 'package:shared_preferences/shared_preferences.dart'; // Importe le package pour le stockage local clÃ©-valeur.

import '../models/message.dart'; // Importe le modÃ¨le de donnÃ©es pour les messages.
import '../widgets/message_bubble.dart'; // Importe le widget pour afficher une bulle de message.
import '../services/chat_service.dart'; // Importe le service pour communiquer avec l'API de chat.
import '../services/auth_service.dart';

// DÃ©finit l'Ã©cran de chat principal de l'application.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key}); // Constructeur du widget.

  @override
  State<ChatScreen> createState() => _ChatScreenState(); // CrÃ©e l'Ã©tat mutable pour ce widget.
}

class _ChatScreenState extends State<ChatScreen> {
  // ClÃ© pour sauvegarder les messages de la conversation active dans SharedPreferences.
  static const _prefsKey = 'chat_messages';
  // ClÃ© pour sauvegarder les conversations archivÃ©es dans SharedPreferences.
  static const _archiveKey = 'conversations_archive';

  // Liste contenant les messages de la conversation en cours.
  final List<Message> _messages = [];
  // ContrÃ´leur pour le champ de saisie de texte.
  final TextEditingController _textController = TextEditingController();
  // ContrÃ´leur pour faire dÃ©filer la liste des messages.
  final ScrollController _scrollController = ScrollController();
  // NÅ“ud de focus pour gÃ©rer le focus du champ de saisie.
  final FocusNode _inputFocus = FocusNode();
  // ClÃ© globale pour accÃ©der Ã  l'Ã©tat du Scaffold (pour ouvrir le tiroir).
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Instance du service de chat, initialisÃ©e plus tard.
  late final ChatService _chatService;

  // BoolÃ©en pour indiquer si l'historique des messages est en cours de chargement.
  bool _loadingHistory = true;
  // Liste pour stocker les conversations archivÃ©es.
  List<Map<String, dynamic>> _archive = [];

  @override
  void initState() { // MÃ©thode appelÃ©e une seule fois lorsque le widget est insÃ©rÃ© dans l'arbre.
    super.initState();
    // DÃ©termine l'URL de base de l'API en fonction de la configuration et de la plateforme.
    final base = kChatBaseUrl.isNotEmpty
        ? kChatBaseUrl
        : (Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000');
    // Initialise le service de chat avec l'URL de base et une mÃ©moire de 5 messages.
    _chatService = ChatService(baseUrl: base, memory: 5, token: authService.token);
    // Charge les messages de la conversation active.
    _loadMessages();
    // Charge les conversations archivÃ©es.
    _loadArchive();
  }

  @override
  void dispose() { // MÃ©thode appelÃ©e lorsque le widget est retirÃ© de l'arbre.
    // LibÃ¨re les ressources des contrÃ´leurs et du nÅ“ud de focus.
    _textController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // Charge les messages de la conversation active depuis SharedPreferences.
  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance(); // Obtient l'instance de SharedPreferences.
      final data = prefs.getString(_prefsKey); // Lit les donnÃ©es des messages.
      final loaded = Message.listFromJsonString(data); // Convertit la chaÃ®ne JSON en une liste de messages.
      setState(() { // Met Ã  jour l'Ã©tat du widget.
        _messages..clear()..addAll(loaded); // Remplace les messages actuels par ceux chargÃ©s.
        _loadingHistory = false; // Indique que le chargement est terminÃ©.
      });
      _scrollToBottom(); // Fait dÃ©filer la liste jusqu'en bas.
    } catch (_) { // En cas d'erreur.
      setState(() => _loadingHistory = false); // Termine l'Ã©tat de chargement mÃªme en cas d'erreur.
    }
  }

  // Sauvegarde les messages de la conversation actuelle dans SharedPreferences.
  Future<void> _persistMessages() async {
    final prefs = await SharedPreferences.getInstance(); // Obtient l'instance de SharedPreferences.
    await prefs.setString(_prefsKey, Message.listToJsonString(_messages)); // Convertit la liste de messages en JSON et la sauvegarde.
  }

  // Charge les conversations archivÃ©es depuis SharedPreferences.
  Future<void> _loadArchive() async {
    final prefs = await SharedPreferences.getInstance(); // Obtient l'instance de SharedPreferences.
    final s = prefs.getString(_archiveKey); // Lit la chaÃ®ne JSON de l'archive.
    if (s != null && s.isNotEmpty) { // Si des donnÃ©es existent.
      try { // GÃ¨re les erreurs de dÃ©codage JSON.
        final list = jsonDecode(s) as List<dynamic>; // DÃ©code la chaÃ®ne JSON.
        setState(() { // Met Ã  jour l'Ã©tat.
          _archive = list.map((e) => e as Map<String, dynamic>).toList(); // Convertit la liste dynamique en une liste de cartes.
        });
      } catch (_) {} // Ignore les erreurs de dÃ©codage.
    }
  }

  // Sauvegarde la liste des conversations archivÃ©es dans SharedPreferences.
  Future<void> _saveArchive() async {
    final prefs = await SharedPreferences.getInstance(); // Obtient l'instance de SharedPreferences.
    await prefs.setString(_archiveKey, jsonEncode(_archive)); // Encode la liste d'archives en JSON et la sauvegarde.
  }

  // Fait dÃ©filer la liste des messages jusqu'Ã  la fin.
  void _scrollToBottom() {
    // S'assure que le dÃ©filement se produit aprÃ¨s la construction de la frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return; // Ne fait rien si le contrÃ´leur n'est pas attachÃ© Ã  une vue.
      _scrollController.animateTo( // Anime le dÃ©filement.
        _scrollController.position.maxScrollExtent, // Vers la position maximale (la fin).
        duration: const Duration(milliseconds: 250), // Sur une durÃ©e de 250ms.
        curve: Curves.easeOut, // Avec une courbe d'animation douce.
      );
    });
  }

  // GÃ©nÃ¨re un titre pour une conversation Ã  partir du premier message de l'utilisateur.
  String _titleFromMessages(List<Message> msgs) {
    try {
      final firstUser = msgs.firstWhere((m) => m.isUser).text.trim(); // Trouve le premier message de l'utilisateur.
      if (firstUser.isEmpty) return 'Nouvelle conversation'; // Retourne un titre par dÃ©faut si le message est vide.
      return firstUser.length > 32 ? firstUser.substring(0, 32) : firstUser; // Tronque le titre s'il est trop long.
    } catch (_) { // Si aucun message de l'utilisateur n'est trouvÃ©.
      return 'Nouvelle conversation'; // Retourne un titre par dÃ©faut.
    }
  }

  // GÃ¨re la crÃ©ation d'une nouvelle conversation.
  Future<void> _newConversation() async {
    if (_messages.isNotEmpty) { // Si la conversation actuelle n'est pas vide.
      final item = <String, dynamic>{ // CrÃ©e un nouvel Ã©lÃ©ment d'archive.
        'title': _titleFromMessages(_messages), // GÃ©nÃ¨re le titre.
        'updatedAt': DateTime.now().toIso8601String(), // Ajoute la date de mise Ã  jour.
        'messages': Message.listToJsonString(_messages), // Ajoute les messages au format JSON.
      };
      setState(() => _archive.insert(0, item)); // Ajoute la conversation archivÃ©e au dÃ©but de la liste.
      await _saveArchive(); // Sauvegarde l'archive.
    }
    setState(() => _messages.clear()); // Vide la liste des messages de la conversation active.
    await _persistMessages(); // Met Ã  jour le stockage persistant.
    _scrollToBottom(); // Fait dÃ©filer (ne fera rien car la liste est vide).
    if (Navigator.canPop(context)) Navigator.of(context).maybePop(); // Ferme le tiroir s'il est ouvert.
  }

  // Ouvre une conversation archivÃ©e et la dÃ©finit comme conversation active.
  Future<void> _openArchived(int index) async {
    if (index < 0 || index >= _archive.length) return; // VÃ©rifie que l'index est valide.
    final s = _archive[index]['messages'] as String?; // RÃ©cupÃ¨re les messages de l'archive.
    final msgs = Message.listFromJsonString(s); // Convertit la chaÃ®ne JSON en liste de messages.
    setState(() { // Met Ã  jour l'Ã©tat.
      _messages..clear()..addAll(msgs); // Remplace les messages actuels par ceux de l'archive.
    });
    await _persistMessages(); // Sauvegarde la nouvelle conversation active.
    _scrollToBottom(); // Fait dÃ©filer jusqu'Ã  la fin.
    if (Navigator.canPop(context)) Navigator.of(context).maybePop(); // Ferme le tiroir.
  }

  // Envoie un message au service de chat et gÃ¨re la rÃ©ponse en streaming.
  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim(); // Nettoie le texte du message.
    if (text.isEmpty) return; // Ne fait rien si le message est vide.

    final userMsg = Message( // CrÃ©e le message de l'utilisateur.
      sender: MessageSender.user,
      text: text,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(userMsg)); // Ajoute le message Ã  la liste.
    await _persistMessages(); // Sauvegarde les messages.
    _scrollToBottom(); // Fait dÃ©filer vers le bas.

    final assistantIndex = _messages.length; // RÃ©cupÃ¨re l'index pour le futur message de l'assistant.
    setState(() { // Ajoute une bulle de message vide pour l'assistant.
      _messages.add(Message(
        sender: MessageSender.assistant,
        text: '',
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom(); // Fait dÃ©filer pour montrer la nouvelle bulle vide.

    try { // GÃ¨re les erreurs de l'API.
      // ItÃ¨re sur le flux de rÃ©ponse du service de chat.
      await for (final chunk in _chatService.replyStream(text, _messages)) {
        setState(() { // Met Ã  jour l'Ã©tat pour chaque morceau de texte reÃ§u.
          final prev = _messages[assistantIndex].text; // RÃ©cupÃ¨re le texte prÃ©cÃ©dent de l'assistant.
          _messages[assistantIndex] = Message( // Met Ã  jour le message de l'assistant.
            sender: MessageSender.assistant,
            text: '$prev${chunk.replaceAll('<END>', '')}', // Ajoute le nouveau morceau au texte.
            timestamp: DateTime.now(), // Met Ã  jour l'horodatage.
          );
        });
        _scrollToBottom(); // Fait dÃ©filer au fur et Ã  mesure que le message s'allonge.
      }
      await _persistMessages(); // Sauvegarde le message complet de l'assistant.
    } catch (e) { // Si une erreur se produit pendant le streaming.
      setState(() { // Met Ã  jour la bulle de l'assistant pour afficher l'erreur.
        _messages[assistantIndex] = Message(
          sender: MessageSender.assistant,
          text: 'Erreur: $e',
          timestamp: DateTime.now(),
        );
      });
      await _persistMessages(); // Sauvegarde le message d'erreur.
      _scrollToBottom(); // Fait dÃ©filer pour voir l'erreur.
    }
  }

  @override
  Widget build(BuildContext context) { // Construit l'interface utilisateur du widget.
    return Scaffold(
      key: _scaffoldKey, // Assigne la clÃ© globale au Scaffold.
      appBar: AppBar( // La barre d'application en haut de l'Ã©cran.
        leading: IconButton( // Widget Ã  gauche de la barre (bouton menu).
          tooltip: 'Menu', // Infobulle.
          icon: const Icon(Icons.menu), // IcÃ´ne du menu.
          onPressed: () => _scaffoldKey.currentState?.openDrawer(), // Ouvre le tiroir de navigation.
        ),
        title: const Text('ChatGPT (demo)'), // Titre de l'application.
        centerTitle: false, // Aligne le titre Ã  gauche.
        actions: [ // Liste des widgets Ã  droite de la barre.
          IconButton( // Bouton pour supprimer la conversation.
            tooltip: 'Supprimer la discussion',
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmClear, // Appelle la fonction de confirmation.
          ),
          IconButton( // Bouton pour le profil utilisateur (action non dÃ©finie).
            onPressed: (){

            }, icon: Icon(Icons.person))
        ],
      ),
      drawer: Drawer( // Le tiroir de navigation latÃ©ral.
        child: SafeArea( // Assure que le contenu du tiroir ne chevauche pas les barres systÃ¨me.
          child: Column( // Organise les Ã©lÃ©ments du tiroir en colonne.
            crossAxisAlignment: CrossAxisAlignment.stretch, // Ã‰tire les enfants sur toute la largeur.
            children: [
              ListTile( // Ã‰lÃ©ment pour "Nouvelle conversation".
                leading: const Icon(Icons.add),
                title: const Text('Nouvelle conversation'),
                onTap: _newConversation, // Appelle la fonction pour crÃ©er une nouvelle conversation.
              ),
              const Divider(height: 1), // Ligne de sÃ©paration.
              Expanded( // La liste des archives prend tout l'espace restant.
                child: _archive.isEmpty
                    ? const Center(child: Text('Aucune conversation archivee')) // Affiche un message si l'archive est vide.
                    : ListView.separated( // Affiche la liste des conversations archivÃ©es.
                        itemCount: _archive.length, // Nombre d'Ã©lÃ©ments dans la liste.
                        separatorBuilder: (_, __) => const Divider(height: 1), // Ajoute un sÃ©parateur entre les Ã©lÃ©ments.
                        itemBuilder: (context, index) { // Construit chaque Ã©lÃ©ment de la liste.
                          final it = _archive[index];
                          final title = (it['title'] as String?) ?? 'Sans titre';
                          final date = (it['updatedAt'] as String?) ?? '';
                          return ListTile(
                            leading: const Icon(Icons.chat_bubble_outline),
                            title: Text(title),
                            subtitle: Text(date),
                            onTap: () => _openArchived(index), // Ouvre l'archive sÃ©lectionnÃ©e.
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      body: Column( // Le corps principal de l'Ã©cran, organisÃ© en colonne.
        children: [
          Expanded( // La zone d'affichage des messages, qui prend l'espace vertical disponible.
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator()) // Affiche un indicateur de chargement.
                : ListView.builder( // Affiche la liste des messages.
                    controller: _scrollController, // Attache le contrÃ´leur de dÃ©filement.
                    padding: const EdgeInsets.only(top: 8, bottom: 8), // Ajoute un peu de padding.
                    itemCount: _messages.length, // Nombre de messages Ã  afficher.
                    itemBuilder: (context, index) { // Construit chaque bulle de message.
                      final msg = _messages[index];
                      return MessageBubble(message: msg);
                    },
                  ),
          ),
          const Divider(height: 1), // Ligne de sÃ©paration avant la barre de saisie.
          SafeArea( // EmpÃªche la barre de saisie de se superposer aux indicateurs systÃ¨me (en bas).
            top: false, // N'applique pas de padding en haut.
            child: Padding( // Ajoute du padding autour de la barre de saisie.
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row( // Organise le champ de texte et le bouton d'envoi horizontalement.
                crossAxisAlignment: CrossAxisAlignment.end, // Aligne les Ã©lÃ©ments en bas.
                children: [
                  Expanded( // Le champ de texte prend l'espace disponible.
                    child: TextField(
                      focusNode: _inputFocus, // Attache le nÅ“ud de focus.
                      controller: _textController, // Attache le contrÃ´leur de texte.
                      minLines: 1, // Hauteur minimale d'une ligne.
                      maxLines: 5, // Hauteur maximale de 5 lignes.
                      textInputAction: TextInputAction.newline, // Permet d'insÃ©rer des sauts de ligne.
                      onSubmitted: (_) {}, // Action Ã  la soumission (non utilisÃ©e ici).
                      decoration: InputDecoration( // DÃ©core le champ de texte.
                        hintText: 'Ecrire un message...', // Texte indicatif.
                        filled: true, // Active le remplissage de fond.
                        fillColor: Colors.grey.shade900, // Couleur de fond.
                        contentPadding: const EdgeInsets.symmetric( // Padding interne.
                          vertical: 12,
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder( // Style de la bordure.
                          borderRadius: BorderRadius.circular(16), // Coins arrondis.
                          borderSide: BorderSide.none, // Pas de bordure visible.
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // Espace entre le champ de texte et le bouton.
                  Container( // Conteneur pour le bouton d'envoi pour personnaliser son apparence.
                    decoration: BoxDecoration(
                      color: Colors.lightBlueAccent, // Couleur de fond.
                      borderRadius: BorderRadius.circular(16), // Coins arrondis.
                    ),
                    child: IconButton( // Le bouton d'envoi.
                      icon: const Icon(Icons.send, color: Colors.white), // IcÃ´ne d'envoi.
                      onPressed: () async { // Action lors de l'appui.
                        final text = _textController.text; // RÃ©cupÃ¨re le texte.
                        _textController.clear(); // Vide le champ de saisie.
                        await sendMessage(text); // Envoie le message.
                        _inputFocus.requestFocus(); // Redonne le focus au champ de saisie.
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Affiche une boÃ®te de dialogue pour confirmer la suppression de la conversation.
  Future<void> _confirmClear() async {
    if (_messages.isEmpty) return; // Ne fait rien si la conversation est dÃ©jÃ  vide.
    final ok = await showDialog<bool>( // Affiche la boÃ®te de dialogue.
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer la conversation ?'),
        content: const Text('Cette action supprimera tous les messages.'),
        actions: [
          TextButton( // Bouton "Annuler".
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton( // Bouton "Supprimer".
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) { // Si l'utilisateur a confirmÃ©.
      setState(() => _messages.clear()); // Vide la liste des messages.
      await _persistMessages(); // Met Ã  jour le stockage.
      _scrollToBottom(); // Fait dÃ©filer (la vue sera vide).
    }
  }
}

