# Script to install optional R packages
packages_to_install <- c('fenr', 'shinydisconnect')

for (pkg in packages_to_install) {
  if (!require(pkg, quietly = TRUE, character.only = TRUE)) {
    cat('Installing package:', pkg, '\n')
    tryCatch({
      install.packages(pkg, repos='https://cran.r-project.org', dependencies=TRUE)
      if (require(pkg, quietly = TRUE, character.only = TRUE)) {
        cat('Successfully installed:', pkg, '\n')
      } else {
        cat('Failed to install:', pkg, '\n')
      }
    }, error = function(e) {
      cat('Error installing', pkg, ':', e$message, '\n')
    })
  } else {
    cat('Package already available:', pkg, '\n')
  }
}

cat('Final check of installed packages:\n')
for (pkg in packages_to_install) {
  available <- require(pkg, quietly = TRUE, character.only = TRUE)
  cat(pkg, ':', available, '\n')
}

cat('Installation complete!\n')
