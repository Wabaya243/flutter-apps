// Importe le package pour l'encodage et le décodage JSON.
import 'dart:convert';

// Énumération pour définir les expéditeurs possibles d'un message.
enum MessageSender { user, assistant }

// Représente un seul message dans une conversation.
class Message {
  // L'expéditeur du message (soit l'utilisateur, soit l'assistant).
  final MessageSender sender;
  // Le contenu textuel du message.
  final String text;
  // La date et l'heure auxquelles le message a été créé.
  final DateTime timestamp;

  // Constructeur pour créer une instance de Message.
  const Message({
    required this.sender, // L'expéditeur est requis.
    required this.text, // Le texte est requis.
    required this.timestamp, // L'horodatage est requis.
  });

  // Getter pratique pour vérifier si le message a été envoyé par l'utilisateur.
  bool get isUser => sender == MessageSender.user;

  // Convertit l'objet Message en une carte (Map) JSON.
  Map<String, dynamic> toJson() => {
        'sender': sender.name, // Convertit l'énumération en une chaîne de caractères (son nom).
        'text': text,
        'timestamp': timestamp.toIso8601String(), // Convertit la date en une chaîne au format ISO 8601.
      };

  // Crée une instance de Message à partir d'une carte JSON.
  static Message fromJson(Map<String, dynamic> json) {
    // Extrait la chaîne de l'expéditeur, avec 'assistant' comme valeur par défaut.
    final senderStr = json['sender'] as String? ?? 'assistant';
    // Convertit la chaîne de l'expéditeur en une valeur de l'énumération MessageSender.
    final sender = senderStr == 'user' ? MessageSender.user : MessageSender.assistant;
    return Message(
      sender: sender,
      // Extrait le texte, avec une chaîne vide comme valeur par défaut.
      text: json['text'] as String? ?? '',
      // Tente de parser la date, avec la date/heure actuelle comme valeur par défaut en cas d'échec.
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }

  // Méthode statique pour créer une liste de Messages à partir d'une chaîne JSON.
  static List<Message> listFromJsonString(String? jsonString) {
    // Si la chaîne est nulle ou vide, retourne une liste vide.
    if (jsonString == null || jsonString.isEmpty) return [];
    try { // Gère les erreurs de décodage JSON.
      // Décode la chaîne JSON en une liste dynamique.
      final list = json.decode(jsonString) as List<dynamic>;
      // Itère sur la liste et convertit chaque élément JSON en un objet Message.
      return list.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) { // Si une erreur se produit.
      return []; // Retourne une liste vide.
    }
  }

  // Méthode statique pour convertir une liste de Messages en une chaîne JSON.
  static String listToJsonString(List<Message> messages) {
    // Itère sur la liste de messages et convertit chaque message en JSON.
    final list = messages.map((m) => m.toJson()).toList();
    // Encode la liste résultante en une seule chaîne JSON.
    return json.encode(list);
  }
}
