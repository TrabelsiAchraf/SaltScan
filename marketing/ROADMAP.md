# Feuille de route Salt Scan

Dernière mise à jour : 4 septembre 2026. La 0.4.0 est fusionnée dans `master`, prête à archiver.
Les métadonnées à coller dans App Store Connect sont dans `marketing/metadata/`, la checklist de
soumission dans `marketing/metadata/README.md`.

## Après la mise en ligne de la 0.4.0 : mesurer pendant 30 jours

Sans SDK d'analytics dans l'app, App Store Connect › Analyses reste la seule source, et elle suffit :

- **Acquisition** : impressions, vues de fiche, taux de conversion, par territoire (US, GB, FR, CA, AU,
  SA, BE) et par source (Recherche App Store vs Navigation vs Référence). Relever la base la semaine de
  la mise en ligne, comparer à 30 jours. Objectif réaliste : impressions de recherche × 3 à 5 grâce aux
  locales, conversion × 2 grâce à la note affichée et aux captures à jour.
- **Notes** : nombre de notes par storefront. Apple n'affiche une moyenne qu'à partir de quelques
  notes ; le seuil à viser est une moyenne visible aux US et au UK.
- **Usage** : sessions, appareils actifs, rétention par cohorte (fournis par App Store Connect pour les
  utilisateurs qui partagent leurs données, sans aucun SDK).
- **Décision sur le nom** : si les US décollent et que le UK reste plat, rouvrir la question
  « Sodium » dans la marque, avec ces chiffres. Sinon, garder « Salt Scan ».
- **Mots-clés** : App Store Connect ne donne pas de données par mot-clé. Option : une campagne Apple
  Search Ads à petit budget (5 $ par jour, US, « sodium tracker » en correspondance exacte, deux
  semaines) pour lire la popularité réelle des requêtes et amorcer les premières notes.

## 0.5 « rester » : rétention

Ordre proposé, du plus rentable au plus coûteux.

### 1. Onboarding par motivation (1 jour)

Au premier lancement, une question : « Pourquoi surveillez-vous le sel ? » avec tension artérielle,
reins, cœur, grossesse, simple curiosité. La réponse prérègle l'objectif et l'unité :

| Motivation | US / CA | Ailleurs |
|---|---|---|
| Tension artérielle, cœur | 1 500 mg (AHA) | 5 g (OMS) |
| Reins | 2 000 mg | 5 g |
| Grossesse, curiosité | 2 300 mg (FDA) | 6 g (UK) ou 5 g (OMS) |

Remplace l'onboarding actuel à trois puces. La motivation n'est stockée que sur l'appareil.

### 2. Widget « anneau du jour » (2 à 3 jours)

WidgetKit, tailles petite et moyenne, plus l'accessoire circulaire de l'écran verrouillé.
Rafraîchi à chaque ajout au journal (`WidgetCenter.reloadAllTimelines`).

Prérequis technique : partager la base SwiftData avec l'extension via un App Group
(`ModelConfiguration(groupContainer:)`) et migrer le magasin existant vers le conteneur partagé au
premier lancement. C'est le point délicat : prévoir une copie du fichier de base puis un basculement,
avec repli sur l'ancien emplacement en cas d'échec.

### 3. Export vers l'app Santé (1 jour)

Écrire `HKQuantityTypeIdentifier.dietarySodium` (en mg) à chaque ligne de journal, effacer la
donnée correspondante quand une ligne est supprimée. Option désactivée par défaut dans les Réglages,
permission HealthKit demandée à l'activation. Nécessite la capability HealthKit et les clés
`NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription`.

### 4. Rappel de fin de journée (à décider, opt-in seulement)

Notification locale vers 20 h si rien n'a été ajouté au journal. Uniquement si l'utilisateur
l'active : la ligne directrice de l'app reste « gratuite et sans dérangement ».

### 5. Outillage et dette

- **Captures iPad** : le jeu iPad en ligne est encore celui de la 0.1. Ajouter une passe iPad 13″
  dans `tools/take_screenshots.sh` et une sortie 2048 × 2732 dans `tools/composite_screenshots.py`.
- **Vidéo App Preview** (20 secondes) quand il y aura du trafic à convertir.
- **Recherche par nom** : `cgi/search.pl` est l'ancienne API d'Open Food Facts ; passer à
  `/api/v2/search` dès qu'elle accepte la recherche plein texte.
- **Firestore** : le secours ne renvoie qu'un nom et un sodium pour quelques produits. Si les
  statistiques Firebase montrent qu'il ne sert plus, retirer Firebase entièrement allège l'app d'une
  dizaine de Mo et supprime `GoogleService-Info.plist`.
- **Tests** : déplacer la logique de `ReviewGate` dans `SaltScanCore` pour la tester ; ajouter
  des tests sur `makeScanEntry` (bridge Open Food Facts → `ScanEntry`).

## 0.6 et au-delà : idées à trier

- Tendances : historique du journal par semaine et par mois, moyenne mobile, objectif hebdomadaire.
- Lecture de l'étiquette par la caméra (Vision, OCR) pour les produits absents d'Open Food Facts,
  fréquent aux US et différenciateur face aux carnets de saisie manuelle.
- Alternatives moins salées : proposer, depuis une fiche, deux produits de la même catégorie Open
  Food Facts avec moins de sel.
- Localisation espagnole (app et fiche es-MX) : les mots-clés es-MX sont indexés aux US.
- Apple Watch : anneau du jour et ajout rapide d'une portion favorite.

## Décisions prises, à ne pas rouvrir sans chiffres

- Marque « Salt Scan », suffixe localisé par storefront (voir `marketing/metadata/`).
- Pas de publicité, pas d'analytics tiers : l'app reste gratuite et discrète.
- Seuils faible / moyen / élevé alignés sur les feux tricolores UK et l'allégation européenne
  « pauvre en sel » : 0,3 g et 1,5 g de sel pour 100 g.
- Stockage toujours en sodium pour 100 g ; l'unité (g de sel ou mg de sodium) n'est qu'un affichage.
