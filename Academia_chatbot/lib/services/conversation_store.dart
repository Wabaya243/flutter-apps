import 'dart:convert'; // Importe le package pour l'encodage et le décodage des données au format JSON.

import 'package:shared_preferences/shared_preferences.dart'; // Importe le package pour le stockage persistant de petites quantités de données clé-valeur.

import '../models/conversation.dart'; // Importe le modèle de données pour les métadonnées de conversation.
import '../models/message.dart'; // Importe le modèle de données pour les messages.

// Gère la persistance (sauvegarde et chargement) des conversations en utilisant SharedPreferences.
class ConversationStore {
  // Clé statique et constante pour stocker la liste des métadonnées de conversation dans SharedPreferences.
  static const _metaKey = 'conv_meta_list_v1';
  // Méthode statique qui génère une clé unique pour stocker les messages d'une conversation spécifique.
  static String _msgsKey(String id) => 'conv_msgs_$id';
  // Clé statique et constante pour stocker l'ID de la conversation actuellement active.
  static const _activeKey = 'conv_active_id_v1';

  // Charge la liste des métadonnées de toutes les conversations depuis SharedPreferences.
  Future<List<ConversationMeta>> loadMetas() async {
    final prefs = await SharedPreferences.getInstance(); // Obtient une instance (singleton) de SharedPreferences.
    final s = prefs.getString(_metaKey); // Lit la chaîne de caractères JSON des métadonnées en utilisant la clé.
    if (s == null || s.isEmpty) return []; // Si la chaîne est nulle ou vide, il n'y a pas de données, retourne une liste vide.
    try { // Bloc try-catch pour gérer les erreurs potentielles lors du décodage JSON.
      final list = (jsonDecode(s) as List<dynamic>) // Décode la chaîne JSON en une liste dynamique.
          .map((e) => ConversationMeta.fromJson(e as Map<String, dynamic>)) // Itère sur la liste et convertit chaque objet JSON en un objet ConversationMeta.
          .toList(); // Convertit l'itérable résultant en une liste.
      return list; // Retourne la liste des métadonnées de conversation.
    } catch (_) { // Si une erreur se produit pendant le décodage.
      return []; // Retourne une liste vide pour éviter de faire planter l'application.
    }
  }

  // Sauvegarde la liste complète des métadonnées de conversation dans SharedPreferences.
  Future<void> saveMetas(List<ConversationMeta> metas) async {
    final prefs = await SharedPreferences.getInstance(); // Obtient une instance de SharedPreferences.
    await prefs.setString( // Enregistre la chaîne de caractères dans SharedPreferences.
      _metaKey, // La clé sous laquelle enregistrer les données.
      jsonEncode(metas.map((e) => e.toJson()).toList()), // Convertit la liste d'objets ConversationMeta en une chaîne JSON.
    );
  }

  // Charge l'ID de la conversation actuellement active depuis SharedPreferences.
  Future<String?> loadActiveId() async {
    final prefs = await SharedPreferences.getInstance(); // Obtient une instance de SharedPreferences.
    return prefs.getString(_activeKey); // Lit la chaîne de caractères de l'ID actif.
  }

  // Sauvegarde l'ID de la conversation active dans SharedPreferences.
  Future<void> saveActiveId(String id) async {
    final prefs = await SharedPreferences.getInstance(); // Obtient une instance de SharedPreferences.
    await prefs.setString(_activeKey, id); // Enregistre l'ID de la conversation active.
  }

  // Charge la liste des messages pour un ID de conversation spécifique.
  Future<List<Message>> loadMessages(String id) async {
    final prefs = await SharedPreferences.getInstance(); // Obtient une instance de SharedPreferences.
    final s = prefs.getString(_msgsKey(id)); // Lit la chaîne JSON des messages pour l'ID donné.
    return Message.listFromJsonString(s); // Utilise une méthode statique du modèle Message pour créer la liste à partir de la chaîne JSON.
  }

  // Sauvegarde la liste des messages pour un ID de conversation spécifique.
  Future<void> saveMessages(String id, List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance(); // Obtient une instance de SharedPreferences.
    await prefs.setString(_msgsKey(id), Message.listToJsonString(messages)); // Utilise une méthode statique du modèle Message pour convertir la liste en chaîne JSON et la sauvegarder.
  }

  // Crée une nouvelle conversation, la sauvegarde et la définit comme active.
  Future<String> createConversation({String? title}) async {
    final metas = await loadMetas(); // Charge la liste actuelle des métadonnées.
    final id = DateTime.now().millisecondsSinceEpoch.toString(); // Génère un ID unique en utilisant le timestamp actuel.
    final meta = ConversationMeta( // Crée une nouvelle instance de métadonnées de conversation.
      id: id, // Assigne l'ID généré.
      title: (title == null || title.isEmpty) ? 'Nouvelle conversation' : title, // Assigne le titre fourni, ou un titre par défaut.
      updatedAt: DateTime.now(), // Définit la date de mise à jour à l'heure actuelle.
    );
    metas.insert(0, meta); // Insère la nouvelle conversation au début de la liste (pour qu'elle apparaisse en haut).
    await saveMetas(metas); // Sauvegarde la liste de métadonnées mise à jour.
    await saveActiveId(id); // Définit l'ID de la nouvelle conversation comme actif.
    await saveMessages(id, []); // Crée une liste de messages vide pour cette nouvelle conversation.
    return id; // Retourne l'ID de la conversation nouvellement créée.
  }

  // Renomme une conversation existante en se basant sur son ID.
  Future<void> renameConversation(String id, String title) async {
    final metas = await loadMetas(); // Charge toutes les métadonnées.
    final idx = metas.indexWhere((m) => m.id == id); // Trouve l'index de la conversation correspondant à l'ID.
    if (idx != -1) { // Vérifie si la conversation a été trouvée.
      metas[idx] = metas[idx].copyWith(title: title, updatedAt: DateTime.now()); // Met à jour le titre et la date de mise à jour de la conversation trouvée.
      await saveMetas(metas); // Sauvegarde la liste de métadonnées modifiée.
    }
  }

  // Met à jour la date de mise à jour d'une conversation (principalement pour la remonter dans la liste).
  Future<void> archiveConversation(String id) async {
    final metas = await loadMetas(); // Charge toutes les métadonnées.
    final idx = metas.indexWhere((m) => m.id == id); // Trouve l'index de la conversation.
    if (idx != -1) { // Si la conversation est trouvée.
      metas[idx] = metas[idx].copyWith(updatedAt: DateTime.now()); // Met à jour uniquement la date de mise à jour.
      await saveMetas(metas); // Sauvegarde la liste de métadonnées modifiée.
    }
  }

  // Efface l'historique des messages d'une conversation, mais conserve la conversation elle-même.
  Future<void> clearMemory(String id) async {
    await saveMessages(id, []); // Remplace la liste des messages existante par une liste vide.
  }

  // Supprime complètement une conversation (ses métadonnées et tous ses messages).
  Future<void> deleteConversation(String id) async {
    final prefs = await SharedPreferences.getInstance(); // Obtient une instance de SharedPreferences.
    // Supprime les messages de cette conversation.
    await prefs.remove(_msgsKey(id));
    // Supprime l'entrée des métadonnées.
    final metas = await loadMetas(); // Charge les métadonnées.
    metas.removeWhere((m) => m.id == id); // Supprime l'élément de la liste dont l'ID correspond.
    await saveMetas(metas); // Sauvegarde la liste de métadonnées mise à jour.
    // Réinitialise l'ID actif si la conversation supprimée était celle qui était active.
    final active = await loadActiveId();
    if (active == id) {
      await saveActiveId(metas.isNotEmpty ? metas.first.id : ''); // Définit la première conversation de la liste comme active, ou une chaîne vide si la liste est vide.
    }
  }
}
