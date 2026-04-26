import 'dart:async'; // Importe les fonctionnalitÃ©s asynchrones comme Stream.
import 'dart:convert'; // Importe les dÃ©codeurs et encodeurs JSON.
import 'dart:io'; // Importe les fonctionnalitÃ©s d'entrÃ©e/sortie.

import 'package:http/http.dart' as http; // Importe le package http pour faire des requÃªtes rÃ©seau.

import '../models/message.dart'; // Importe le modÃ¨le de donnÃ©es pour les messages.

class ChatService {  final String baseUrl;  final String? apiKey;  final int memory;  final String? token; // Le nombre de derniers messages (utilisateur+assistant) Ã  envoyer dans le contexte.

  ChatService({ required this.baseUrl, this.apiKey, this.memory = 5, this.token, });

  // Construit le contexte de la discussion Ã  partir de l'historique local des messages.
  List<Map<String, String>> _buildContext(List<Message> history, String userText) {
    final system = { // DÃ©finit le message systÃ¨me qui instruit le modÃ¨le.
      'role': 'system',
      'content': ("Tu es un conseiller acadÃ©mique de lâ€™UniversitÃ© de Kinshasa. "
          "Tu es un conseiller UNIKIN. Donne des rÃ©ponses claires et structurÃ©es. Ne rÃ©vÃ¨le jamais ton raisonnement interne"
      "RÃ©ponds dans un franÃ§ais fluide, logique et bienveillant. "
      "Sois clair, rigoureux et explicatif. Nâ€™utilise jamais lâ€™anglais, "
          "mÃªme si la question est en anglais : traduis toujours et rÃ©ponds en franÃ§ais uniquement.")
    };

    // Conserve uniquement les 'memory' derniers messages de l'utilisateur et de l'assistant.
    final ua = history // Filtre l'historique pour ne garder que les messages de l'utilisateur et de l'assistant.
        .where((m) => m.sender == MessageSender.user || m.sender == MessageSender.assistant)
        .toList();
    final last = ua.length > memory ? ua.sublist(ua.length - memory) : ua; // Prend les `memory` derniers messages, ou tous si moins.

    final ctx = <Map<String, String>>[system]; // Initialise le contexte avec le message systÃ¨me.
    for (final m in last) { // ItÃ¨re sur les derniers messages.
      ctx.add({ // Ajoute chaque message au contexte.
        'role': m.sender == MessageSender.user ? 'user' : 'assistant', // DÃ©finit le rÃ´le.
        'content': m.text, // Ajoute le contenu du message.
      });
    }
    // Ajoute le nouveau message de l'utilisateur.
    ctx.add({'role': 'user', 'content': userText});
    return ctx; // Retourne le contexte complet.
  }

  // Extrait un morceau de texte Ã  partir de diffÃ©rentes formes JSON.
  String _extractChunk(Map<String, dynamic> obj) {
    // Type OpenAI : choices[0].delta.content
    final choices = obj['choices']; // RÃ©cupÃ¨re la liste 'choices'.
    if (choices is List && choices.isNotEmpty) { // VÃ©rifie si 'choices' est une liste non vide.
      final first = choices.first; // Prend le premier Ã©lÃ©ment.
      if (first is Map && first['delta'] is Map) { // VÃ©rifie la structure interne.
        final content = (first['delta'] as Map)['content']; // Extrait le contenu.
        if (content is String) return content; // Retourne le contenu s'il existe.
      }
    }
    // { delta: { content: ... } }
    final delta = obj['delta']; // RÃ©cupÃ¨re l'objet 'delta'.
    if (delta is Map && delta['content'] is String) return delta['content'] as String; // Retourne le contenu de 'delta'.
    // { content: ... }
    if (obj['content'] is String) return obj['content'] as String; // Retourne le contenu directement.
    // { reply: ... }
    if (obj['reply'] is String) return obj['reply'] as String; // Retourne la 'reply'.
    return ''; // Retourne une chaÃ®ne vide si aucun contenu n'est trouvÃ©.
  }

  // Diffuse les jetons de l'assistant depuis le backend en utilisant SSE (Server-Sent Events).
  // Vous pouvez passer un sessionId par conversation et un drapeau de rÃ©initialisation au dÃ©but d'une nouvelle discussion
  // afin que le serveur puisse oublier tout contexte prÃ©cÃ©dent s'il est avec Ã©tat.
  Stream<String> replyStream( // MÃ©thode pour obtenir une rÃ©ponse en streaming.
    String userText, // Le texte envoyÃ© par l'utilisateur.
    List<Message> history, { // L'historique de la conversation.
    String? sessionId, // L'ID de session optionnel.
    bool reset = false, // Un drapeau pour rÃ©initialiser la conversation cÃ´tÃ© serveur.
  }) async* { // Utilise async* pour retourner un Stream.
    final client = http.Client(); // CrÃ©e un nouveau client HTTP.
    try { // Bloc try pour gÃ©rer les erreurs potentielles.
      final ctx = _buildContext(history, userText); // Construit le contexte de la requÃªte.
      final uri = Uri.parse('$baseUrl/chat/stream'); // CrÃ©e l'URI pour la requÃªte de streaming.
      final req = http.Request('POST', uri); // CrÃ©e une requÃªte POST.
      req.headers['Content-Type'] = 'application/json'; // DÃ©finit le type de contenu.
      req.headers['Accept'] = 'text/event-stream'; // Accepte les Server-Sent Events.
      req.headers['Cache-Control'] = 'no-cache'; // DÃ©sactive le cache.
      req.headers['Connection'] = 'keep-alive'; // Maintient la connexion ouverte.
      // Ajoute le token si disponible
      if (token != null && token!.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer ' + token!;
      }
      req.body = jsonEncode({ // Encode le corps de la requÃªte en JSON.
        'message': userText,
        'messages': ctx,
        'stream': true,
        if (sessionId != null) 'session_id': sessionId, // Ajoute l'ID de session si prÃ©sent.
        if (reset) 'reset': true, // Ajoute le drapeau de rÃ©initialisation si vrai.
      });

      final streamed = await client.send(req).timeout(const Duration(seconds: 20)); // Envoie la requÃªte et attend une rÃ©ponse streamÃ©e (avec un timeout).
      // DÃ©code ligne par ligne.
      final lines = streamed.stream.transform(utf8.decoder).transform(const LineSplitter()); // Transforme le flux de bytes en un flux de lignes de texte.
      await for (final line in lines) { // ItÃ¨re sur chaque ligne du flux.
        if (line.isEmpty) continue; // Ignore les lignes vides.
        if (line.startsWith('data:')) { // Si la ligne est un Ã©vÃ©nement SSE.
          final data = line.substring(5).trim(); // Extrait les donnÃ©es de l'Ã©vÃ©nement.
          if (data == '[DONE]') break; // ArrÃªte si le marqueur de fin est reÃ§u.
          try { // Essaie de dÃ©coder les donnÃ©es en JSON.
            final obj = json.decode(data) as Map<String, dynamic>;
            var chunk = _extractChunk(obj); // Extrait le morceau de texte.
            if (chunk.isNotEmpty) { // Si un morceau est extrait.
              chunk = chunk.replaceAll('<END>', ''); // Nettoie le morceau.
              if (chunk.isNotEmpty) yield chunk; // Produit le morceau dans le stream de sortie.
            }
          } catch (_) { // Si le dÃ©codage JSON Ã©choue.
            // Si ce n'est pas du JSON, traiter comme du texte brut.
            var txt = data.replaceAll('<END>', ''); // Nettoie le texte brut.
            if (txt.isNotEmpty) yield txt; // Produit le texte brut.
          }
        }
      }
    } catch (e) { // Attrape les erreurs (timeout, etc.).
      // Ne plus fallback: on propage l'erreur pour affichage dans l'UI.
      throw e; // Relance l'erreur pour qu'elle soit gÃ©rÃ©e par l'appelant.
    } finally { // Bloc qui s'exÃ©cute toujours.
      client.close(); // Ferme le client HTTP pour libÃ©rer les ressources.
    }
  }
}



