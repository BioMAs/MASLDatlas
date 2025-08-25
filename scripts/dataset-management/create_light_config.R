# Solution temporaire pour le dataset "Fibrotic Integrated Cross Species-002"
# Ce script modifie la configuration pour utiliser un dataset plus petit temporairement

# Lire la configuration actuelle
datasets_config <- jsonlite::fromJSON("config/datasets_config.json")

# Créer une version de test sans le gros dataset
datasets_config_light <- datasets_config

# Remplacer temporairement le gros dataset par un avertissement
datasets_config_light$Integrated$Datasets <- "Dataset too large - optimization in progress"

# Sauvegarder la configuration temporaire
jsonlite::write_json(datasets_config_light, "config/datasets_config_light.json", pretty = TRUE, auto_unbox = TRUE)

cat("✅ Configuration allégée créée dans: config/datasets_config_light.json\n")
cat("💡 Pour utiliser cette configuration, modifiez app.R pour charger ce fichier temporairement\n")
