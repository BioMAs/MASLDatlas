# Script to install optional R packages
packages_to_install <- c('shinydisconnect')
github_packages <- c('fenr')

# Install CRAN packages
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

# Install remotes if not available (needed for GitHub packages)
if (!require('remotes', quietly = TRUE)) {
  cat('Installing remotes package for GitHub installations...\n')
  install.packages('remotes', repos='https://cran.r-project.org')
}

# Install GitHub packages  
for (pkg in github_packages) {
  if (!require(pkg, quietly = TRUE, character.only = TRUE)) {
    cat('Installing GitHub package:', pkg, '\n')
    tryCatch({
      if (pkg == 'fenr') {
        # fenr is available on CRAN, try both methods
        tryCatch({
          install.packages('fenr', repos='https://cran.r-project.org', dependencies=TRUE)
        }, error = function(e1) {
          cat('CRAN installation failed, trying GitHub...\n')
          remotes::install_github('bartongroup/fenr', force = TRUE)
        })
      }
      
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
all_packages <- c(packages_to_install, github_packages)
for (pkg in all_packages) {
  available <- require(pkg, quietly = TRUE, character.only = TRUE)
  cat(pkg, ':', available, '\n')
}

cat('Installation complete!\n')
