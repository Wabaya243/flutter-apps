// Importation des packages nécessaires pour le projet.
import 'package:apps_meteo/Temperature.dart'; // Gestion des données de température.
import 'package:flutter/material.dart'; // UI toolkit pour construire l'interface utilisateur.
import 'package:flutter/services.dart'; // Pour accéder aux services de plateforme, comme l'orientation de l'écran.
import 'dart:async'; // Support pour la programmation asynchrone avec des futures et des streams.
import 'package:shared_preferences/shared_preferences.dart'; // Stockage de données clé-valeur sur le dispositif.
import 'package:location/location.dart' as loc; // Accès aux services de localisation du dispositif.
import 'package:geocoding/geocoding.dart'; // Conversion des coordonnées géographiques en adresses et vice versa.
import 'package:http/http.dart' as http; // Pour effectuer des requêtes HTTP.
import 'dart:convert'; // Pour encoder et décoder des données en format JSON.
import 'my_flutter_app_icons.dart'; // Importation des icônes personnalisées.

// Point d'entrée principal de l'application Flutter.
void main() {
  WidgetsFlutterBinding.ensureInitialized(); // S'assure que l'interface utilisateur est initialisée.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]); // Verrouille l'orientation en mode portrait.
  runApp(const MyApp()); // Lance l'application.
}

// Widget racine de l'application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meteo wabaya', // Titre de l'application.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), // Thème de couleurs basé sur le pourpre.
        useMaterial3: true, // Utilise Material Design 3.
      ),
      debugShowCheckedModeBanner: false, // Enlève la bannière de débogage.
      home: const MyHomePage(title: 'Meteo Wabaya'), // Page d'accueil de l'application.
    );
  }
}


// Widget pour la page d'accueil, état modifiable car les données peuvent changer.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title}); // Constructeur qui prend un titre.
  final String title; // Titre de la page.

  @override
  State<MyHomePage> createState() => _MyHomePageState(); // Crée l'état associé à la page.
}

// État de la page d'accueil.
class _MyHomePageState extends State<MyHomePage> {
  // Déclarations et initialisations de variables.
  String key = 'villes'; // Clé pour stocker les villes dans les préférences partagées.
  List<String> villes = [""]; // Liste des villes.
  String villeChoisi = ''; // Ville choisie par l'utilisateur.
  String currentCityName = ""; // Nom de la ville actuelle basée sur la localisation.
  late loc.Location location; // Instance pour accéder à la localisation.
  loc.LocationData? locationData; // Données de localisation actuelles.
  late Stream<loc.LocationData> stream; // Stream pour écouter les changements de localisation.
  double? latitudeVilleChoisie; // Latitude de la ville choisie.
  double? longitudeVilleChoisie; // Longitude de la ville choisie.
  Temperature? temperature; // Données de température obtenues de l'API.

  // Différentes images utilisées comme arrière-plan en fonction du temps.
  AssetImage night = const AssetImage("assets/n.jpg");
  AssetImage default1 = const AssetImage("assets/n.jpg");
  AssetImage sunset = const AssetImage("assets/01.webp");
  AssetImage sunclouds = const AssetImage("assets/03.webp");
  AssetImage clouds = const AssetImage("assets/04.webp");
  AssetImage rain = const AssetImage("assets/09.webp");
  AssetImage thunder = const AssetImage("assets/11.webp");
  AssetImage snow = const AssetImage("assets/13.webp");
  AssetImage mist = const AssetImage("assets/50.webp");

  // Méthode appelée lorsque cet objet est inséré dans l'arbre.
  @override
  void initState() {
    super.initState(); // Appel à la méthode initState de la classe mère.
    obtenir(); // Récupère les villes stockées.
    location = loc.Location(); // Initialise l'instance de localisation.
    listenToStream(); // Commence à écouter les changements de localisation.
    getInitialLocation(); // Obtient la localisation initiale.
  }

  // Obtient la localisation initiale de l'utilisateur.
  void getInitialLocation() async {
    locationData = await location.getLocation(); // Demande la localisation actuelle.
    listenToStream(); // Réécoute les changements de localisation au cas où ils n'étaient pas déjà écoutés.
  }

  // Met à jour les données de température avec de nouvelles valeurs.
  void updateTemperature(Temperature newTemperature) {
    setState(() { // Notifie le framework qu'une mise à jour est nécessaire.
      temperature = newTemperature; // Met à jour la température avec les nouvelles données.
    });
  }

  // Construit l'interface utilisateur de la page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blueGrey, // Couleur de fond de l'application.
        appBar: AppBar( // Barre d'application en haut.
          centerTitle: true, // Centre le titre.
          title: Text((villeChoisi == '') ? " METEO WABAYA " : villeChoisi), // Affiche le nom de la ville choisie ou un titre par défaut.
          backgroundColor: Colors.indigo[400], // Couleur de la barre d'application.
        ),
        drawer: Drawer( // Menu latéral pour la sélection des villes.
          child: Container(
            color: Colors.indigo[400], // Couleur de fond du menu.
            child: ListView.builder( // Construit une liste d'éléments.
                itemCount: villes.length + 2, // Nombre total d'éléments dans la liste.
                itemBuilder: (context, i) { // Fonction pour construire chaque élément.
                  if (i == 0) { // Premier élément : en-tête du menu.
                    return DrawerHeader( // En-tête du menu.
                        child: Column( // Contient le titre et le bouton pour ajouter une ville.
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Espacement vertical.
                          children: [
                            textAvecStyle("Mes villes", fontSize: 23.0), // Affiche "Mes villes".
                            TextButton( // Bouton pour ajouter une nouvelle ville.
                                style: TextButton.styleFrom(
                                    backgroundColor: Colors.blue, elevation: 20), // Style du bouton.
                                onPressed: ajoutVille, // Appelée quand le bouton est pressé.
                                child: textAvecStyle("Ajoutez une nouvelle ville", // Texte du bouton.
                                    color: Colors.white))
                          ],
                        ));
                  } else if (i == 1) { // Deuxième élément : option pour sélectionner la ville actuelle.
                    return ListTile( // Élément de liste pour la ville actuelle.
                      title: textAvecStyle(currentCityName), // Affiche le nom de la ville actuelle.
                      onTap: () { // Quand cet élément est tapé.
                        setState(() { // Met à jour l'état de l'application.
                          villeChoisi = ''; // Réinitialise la ville choisie.
                          latitudeVilleChoisie = null; // Réinitialise la latitude de la ville choisie.
                          longitudeVilleChoisie = null; // Réinitialise la longitude de la ville choisie.
                          apiForCurrentLocation(); // Appelle l'API pour obtenir les données météorologiques de la localisation actuelle.
                          Navigator.pop(context); // Ferme le menu latéral.
                        });
                      },
                    );
                  } else { // Autres éléments : liste des villes enregistrées.
                    String ville = villes[i - 2]; // Obtient le nom de la ville à partir de la liste.
                    return ListTile( // Élément de liste pour chaque ville enregistrée.
                      title: textAvecStyle(ville), // Affiche le nom de la ville.
                      trailing: IconButton( // Bouton pour supprimer la ville de la liste.
                          onPressed: (() => supprimer(ville)), // Appelée quand le bouton est pressé.
                          icon: const Icon(Icons.delete_forever, color: Colors.black,)), // Icône du bouton.
                      onTap: () { // Quand cet élément est tapé.
                        if (i - 2 < villes.length) { // Vérifie si l'indice est valide.
                          setState(() { // Met à jour l'état de l'application.
                            villeChoisi = villes[i - 2]; // Met à jour la ville choisie avec la ville sélectionnée.
                            coordsFromCity(); // Obtient les coordonnées de la ville choisie.
                            Navigator.pop(context); // Ferme le menu latéral.
                          });
                        }
                      },
                    );
                  }
                }),
          ),
        ),
        body: (temperature == null) ? // Si les données de température ne sont pas disponibles.
        Center( // Affiche un widget au centre de l'écran.
            child: Text((villeChoisi == '') ? currentCityName : villeChoisi)) // Affiche le nom de la ville choisie ou la ville actuelle.
            : Container( // Si les données de température sont disponibles.
          width: MediaQuery.of(context).size.width, // Largeur de l'écran.
          height: MediaQuery.of(context).size.height, // Hauteur de l'écran.
          decoration: BoxDecoration( // Décoration du conteneur.
              image: DecorationImage(image: getBackGround(), // Image de fond basée sur les conditions météorologiques.
                  fit: BoxFit.cover // Couvre tout l'espace disponible.
              )
          ),
          child: Column( // Contient les informations météorologiques.
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Espacement vertical.
            children: [
              textAvecStyle((villeChoisi == null) ? currentCityName : villeChoisi, fontSize: 50.0, fontStyle: FontStyle.italic, color: Colors.white), // Affiche le nom de la ville.
              textAvecStyle(temperature!.description, fontSize: 40.0, color: Colors.black), // Description de la météo.
              Row( // Ligne contenant l'icône de la météo et la température.
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Espacement horizontal.
                children: [
                  Image.asset(temperature!.icon), // Icône de la météo.
                  textAvecStyle("${temperature!.temp} °C", fontSize: 40.0, color: Colors.white), // Température.
                ],
              ),
              Row( // Ligne contenant des informations supplémentaires sur la météo.
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Espacement horizontal.
                children: [
                  extra("${temperature!.temp_min.toInt()} °C", MyFlutterApp.down), // Température minimale.
                  extra("${temperature!.temp_max.toInt()} °C", MyFlutterApp.up), // Température maximale.
                  extra("${temperature!.pressure.toInt()} ", MyFlutterApp.drizzle), // Pression atmosphérique.
                  extra("${temperature!.humidity.toInt()} %", MyFlutterApp.temperatire), // Humidité.
                ],
              )

            ],
          ),
        )
    );
  }

  // Méthode pour créer un widget contenant des informations supplémentaires avec une icône.
  Column extra(String data, IconData iconData){
    return Column( // Colonne pour aligner verticalement les éléments.
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Espacement vertical.
      children: [
        Icon(iconData, color: Colors.white, size: 38.0,), // Icône.
        textAvecStyle(data, color: Colors.white), // Texte des informations.
      ],
    );
  }

  // Méthode pour créer un widget de texte stylisé.
  Text textAvecStyle(String data,
      {color = Colors.black,
        fontSize = 19.0,
        fontStyle = FontStyle.italic,
        textAlign = TextAlign.center}) {
    return Text(
      data, // Texte à afficher.
      textAlign: textAlign, // Alignement du texte.
      style: TextStyle( // Style du texte.
        color: color, // Couleur du texte.
        fontSize: fontSize, // Taille de la police.
        fontStyle: fontStyle, // Style de la police (italique).
      ),
    );
  }

  // Affiche une boîte de dialogue pour ajouter une nouvelle ville.
  Future<void> ajoutVille() async {
    return showDialog( // Affiche une boîte de dialogue.
        barrierDismissible: true, // Permet de fermer la boîte en tapant en dehors.
        context: context, // Contexte de l'application.
        builder: (BuildContext buildcontext) { // Construit le contenu de la boîte.
          return SimpleDialog( // Utilise un SimpleDialog pour un affichage simple.
            contentPadding: const EdgeInsets.all(20.0), // Padding autour du contenu.
            title: textAvecStyle("Ajoutez une nouvelle ville", // Titre de la boîte.
                fontSize: 22.0, color: Colors.black),
            children: [
              TextField( // Champ de texte pour saisir le nom de la ville.
                decoration: const InputDecoration(labelText: "ville: "), // Décoration du champ.
                onSubmitted: (String str) { // Appelée quand l'utilisateur soumet le texte.
                  ajouter(str); // Ajoute la ville aux préférences partagées.
                  Navigator.pop(buildcontext); // Ferme la boîte de dialogue.
                },
              )
            ],
          );
        });
  }

  // Récupère la liste des villes stockées dans les préférences partagées.
  void obtenir() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance(); // Obtient une instance des préférences partagées.
    List<String>? liste = await sharedPreferences.getStringList(key); // Récupère la liste des villes.
    if (liste != null) { // Si la liste n'est pas vide.
      setState(() { // Met à jour l'état de l'application.
        villes = liste; // Met à jour la liste des villes avec les données récupérées.
      });
    }
  }

  // Ajoute une ville aux préférences partagées.
  void ajouter(String str) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance(); // Obtient une instance des préférences partagées.
    villes.add(str); // Ajoute la nouvelle ville à la liste.
    await sharedPreferences.setStringList(key, villes); // Enregistre la liste mise à jour dans les préférences partagées.
    obtenir(); // Récupère la liste mise à jour pour afficher dans l'interface utilisateur.
  }

  // Supprime une ville des préférences partagées.
  void supprimer(String str) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance(); // Obtient une instance des préférences partagées.
    villes.remove(str); // Supprime la ville de la liste.
    await sharedPreferences.setStringList(key, villes); // Enregistre la liste mise à jour dans les préférences partagées.
    obtenir(); // Récupère la liste mise à jour pour afficher dans l'interface utilisateur.
  }

  // Détermine l'image de fond à utiliser en fonction des conditions météorologiques.
  AssetImage getBackGround() {
    var iconId = temperature!.icon.split('/').last.split('.').first; // Extrait l'identifiant de l'icône météo.

    // Sélectionne l'image de fond en fonction de l'identifiant de l'icône.
    if (iconId == 'n') {
      return night; // Nuit.
    } else if (iconId == '01' || iconId == '02') {
      return sunset; // Coucher de soleil.
    } else if (iconId == "03") {
      return sunclouds; // Soleil avec nuages.
    } else if (iconId == "04") {
      return clouds; // Nuageux.
    } else if (iconId == "09" || iconId == '10') {
      return rain; // Pluie.
    } else if (iconId == "11") {
      return thunder; // Orage.
    } else if (iconId == "13") {
      return snow; // Neige.
    } else if (iconId == "50") {
      return mist; // Brume.
    } else {
      return default1; // Image par défaut si aucune correspondance n'est trouvée.
    }
  }

  // Écoute les changements de localisation.
  listenToStream() {
    stream = location.onLocationChanged; // Obtient le stream des changements de localisation.
    stream.listen((newPosition) { // Écoute les nouveaux événements du stream.
      if ((locationData == null) || (newPosition.longitude != locationData!.longitude) && (newPosition.latitude != locationData!.latitude)) {
        // Si les données de localisation sont nulles ou si la localisation a changé.
        setState(() { // Met à jour l'état de l'application.
          locationData = newPosition; // Met à jour les données de localisation.
          locationToString(); // Convertit les coordonnées géographiques en nom de ville.
        });
      }
    });
  }

  // Obtient les coordonnées géographiques de la ville choisie.
  void coordsFromCity() async {
    if (villeChoisi.isNotEmpty) { // Si une ville est choisie.
      try {
        List<Location> locations = await locationFromAddress(villeChoisi); // Convertit le nom de la ville en coordonnées géographiques.
        if (locations.isNotEmpty) { // Si la conversion réussit.
          Location location = locations.first; // Prend la première localisation retournée.
          setState(() { // Met à jour l'état de l'application.
            latitudeVilleChoisie = location.latitude; // Met à jour la latitude.
            longitudeVilleChoisie = location.longitude; // Met à jour la longitude.
            api(); // Appelle l'API météo avec les nouvelles coordonnées.
          });
        }
      } catch (e) {
        print("Erreur lors de la recherche des coordonnées : $e"); // Affiche l'erreur en cas d'échec.
      }
    }
  }

  // Convertit les coordonnées géographiques actuelles en nom de ville.
  void locationToString() async {
    if (locationData != null) { // Si les données de localisation sont disponibles.
      try {
        final addresses = await placemarkFromCoordinates(locationData!.latitude!, locationData!.longitude!); // Convertit les coordonnées en adresses.
        if (addresses.isNotEmpty) { // Si la conversion réussit.
          final cityName = addresses.first.locality; // Prend le nom de la localité de la première adresse retournée.
          setState(() { // Met à jour l'état de l'application.
            currentCityName = cityName ?? ''; // Met à jour le nom de la ville actuelle.
            apiForCurrentLocation(); // Appelle l'API météo pour la localisation actuelle.
          });
        }
      } catch (e) {
        print("Erreur lors de la récupération de l'adresse: $e"); // Affiche l'erreur en cas d'échec.
      }
    }
  }

  // Appelle l'API météo pour la localisation actuelle.
  void apiForCurrentLocation() async {
    if (locationData != null) { // Si les données de localisation sont disponibles.
      final key = "&APPID=207aa050eff50bd5bf45e309aab36814"; // Clé de l'API.
      String lang = "&lang=${Localizations.localeOf(context).languageCode}"; // Langue basée sur les paramètres régionaux de l'application.
      String baseAPI = "https://api.openweathermap.org/data/2.5/weather?"; // URL de base de l'API météo.
      String coordsString = "lat=${locationData!.latitude}&lon=${locationData!.longitude}"; // Chaîne de requête avec les coordonnées.
      String units = "&units=metric"; // Utilise le système métrique pour les unités.
      String totalString = baseAPI + coordsString + units + lang + key; // URL complète de la requête API.
      Uri url = Uri.parse(totalString); // Convertit la chaîne en URI.
      final response = await http.get(url); // Exécute la requête HTTP.

      if (response.statusCode == 200) { // Si la requête réussit.
        Map map = json.decode(response.body); // Décode la réponse JSON en un objet Map.
        setState(() { // Met à jour l'état de l'application.
          temperature = Temperature(map); // Crée une instance de Temperature avec les données reçues.
          if (villeChoisi.isEmpty) {
            villeChoisi = currentCityName; // Met à jour la ville choisie avec le nom de la ville actuelle si villeChoisi est vide.
          }
        });
      } else {
        print("Erreur API: ${response.statusCode}"); // Affiche le code d'erreur en cas d'échec de la requête.
      }
    }
  }

  // Appelle l'API météo pour la ville choisie.
  api() async {
    if (latitudeVilleChoisie != null && longitudeVilleChoisie != null) { // Si les coordonnées de la ville choisie sont disponibles.
      final key = "&APPID=207aa050eff50bd5bf45e309aab36814"; // Clé de l'API.
      String lang = "&lang=${Localizations.localeOf(context).languageCode}"; // Langue basée sur les paramètres régionaux de l'application.
      String baseAPI = "https://api.openweathermap.org/data/2.5/weather?"; // URL de base de l'API météo.
      String coordsString = "lat=$latitudeVilleChoisie&lon=$longitudeVilleChoisie"; // Chaîne de requête avec les coordonnées de la ville choisie.
      String units = "&units=metric"; // Utilise le système métrique pour les unités.
      String totalString = baseAPI + coordsString + units + lang + key; // URL complète de la requête API.
      Uri url = Uri.parse(totalString); // Convertit la chaîne en URI.
      final response = await http.get(url); // Exécute la requête HTTP.

      if (response.statusCode == 200) { // Si la requête réussit.
        Map map = json.decode(response.body); // Décode la réponse JSON en un objet Map.
        setState(() {
          temperature = Temperature(map);
        });
      } else {
        print("Erreur lors de l'accès à l'API: ${response.statusCode}");
      }
    } else {
      print("Coordonnées non disponibles");
    }
  }
}