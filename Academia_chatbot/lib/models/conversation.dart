// Représente les métadonnées d'une conversation, utilisées pour afficher la liste des conversations.
class ConversationMeta {
  // L'identifiant unique de la conversation.
  final String id;
  // Le titre de la conversation, affiché dans la liste.
  final String title;
  // La date et l'heure de la dernière mise à jour de la conversation.
  final DateTime updatedAt;

  // Constructeur pour créer une instance de ConversationMeta.
  const ConversationMeta({
    required this.id, // L'ID est requis.
    required this.title, // Le titre est requis.
    required this.updatedAt, // La date de mise à jour est requise.
  });

  // Crée une copie de cette instance avec les champs fournis remplacés.
  ConversationMeta copyWith({String? title, DateTime? updatedAt}) {
    return ConversationMeta(
      id: id, // L'ID reste le même.
      title: title ?? this.title, // Utilise le nouveau titre s'il est fourni, sinon conserve l'ancien.
      updatedAt: updatedAt ?? this.updatedAt, // Utilise la nouvelle date si elle est fournie, sinon conserve l'ancienne.
    );
  }

  // Convertit l'objet ConversationMeta en une carte JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(), // Convertit la date en une chaîne de caractères au format ISO 8601.
      };

  // Crée une instance de ConversationMeta à partir d'une carte JSON.
  static ConversationMeta fromJson(Map<String, dynamic> json) {
    return ConversationMeta(
      id: json['id'] as String, // Extrait l'ID du JSON.
      title: (json['title'] as String?) ?? 'Nouvelle conversation', // Extrait le titre, avec une valeur par défaut.
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(), // Tente de parser la date, avec des valeurs par défaut en cas d'échec.
    );
  }
}
