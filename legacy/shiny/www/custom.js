/* ==========================================================================
   MASLDatlas - JavaScript Interactif
   Amélioration de l'expérience utilisateur avec des interactions dynamiques
   ========================================================================== */

$(document).ready(function() {
    console.log("🚀 MASLDatlas Interface Enhancement Loaded");
    
    // ==========================================================================
    // Gestionnaire de Chargement Global
    // ==========================================================================
    
    let loadingOverlay = null;
    
    function showGlobalLoading(message = "Chargement...") {
        if (loadingOverlay) return; // Éviter les doublons
        
        loadingOverlay = $(`
            <div class="loading-overlay" id="globalLoading">
                <div class="text-center">
                    <div class="loading-spinner"></div>
                    <h4 class="mt-3 text-primary">${message}</h4>
                </div>
            </div>
        `);
        
        $('body').append(loadingOverlay);
        loadingOverlay.fadeIn(200);
    }
    
    function hideGlobalLoading() {
        if (loadingOverlay) {
            loadingOverlay.fadeOut(200, function() {
                $(this).remove();
                loadingOverlay = null;
            });
        }
    }
    
    // ==========================================================================
    // Améliorations des Boutons et Interactions
    // ==========================================================================
    
    // Animation de clic pour tous les boutons
    $(document).on('click', '.btn', function() {
        const btn = $(this);
        
        // Ajouter l'effet de ripple
        const ripple = $('<span class="ripple"></span>');
        btn.append(ripple);
        
        // Animation du ripple
        ripple.css({
            'position': 'absolute',
            'border-radius': '50%',
            'background': 'rgba(255,255,255,0.6)',
            'transform': 'scale(0)',
            'animation': 'ripple 0.6s linear',
            'left': '50%',
            'top': '50%',
            'width': '20px',
            'height': '20px',
            'margin-left': '-10px',
            'margin-top': '-10px'
        });
        
        // Supprimer le ripple après l'animation
        setTimeout(() => ripple.remove(), 600);
    });
    
    // CSS pour l'animation ripple
    $('<style>').text(`
        @keyframes ripple {
            to {
                transform: scale(4);
                opacity: 0;
            }
        }
        .btn {
            position: relative;
            overflow: hidden;
        }
    `).appendTo('head');
    
    // ==========================================================================
    // Gestion du Chargement des Datasets
    // ==========================================================================
    
    $(document).on('click', '#import_dataset', function() {
        const organism = $('#selection_organism').val();
        const dataset = $('#selection_dataset').val();
        
        if (organism && dataset) {
            showGlobalLoading(`Chargement du dataset ${dataset} pour ${organism}...`);
            
            // Observer les changements dans l'interface pour détecter la fin du chargement
            const observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    if (mutation.type === 'childList') {
                        // Vérifier si des images UMAP sont apparues
                        if ($('#imageoutput_UMAP img').length > 0) {
                            setTimeout(() => {
                                hideGlobalLoading();
                                showSuccessNotification('Dataset chargé avec succès!');
                                observer.disconnect();
                            }, 1000);
                        }
                    }
                });
            });
            
            observer.observe(document.body, {
                childList: true,
                subtree: true
            });
            
            // Timeout de sécurité
            setTimeout(() => {
                hideGlobalLoading();
                observer.disconnect();
            }, 300000); // 5 minutes max
        }
    });
    
    // ==========================================================================
    // Système de Notifications
    // ==========================================================================
    
    function showNotification(message, type = 'info', duration = 3000) {
        const iconMap = {
            'success': 'fas fa-check-circle',
            'warning': 'fas fa-exclamation-triangle',
            'error': 'fas fa-times-circle',
            'info': 'fas fa-info-circle'
        };
        
        const notification = $(`
            <div class="notification alert alert-${type} alert-dismissible fade show" 
                 style="position: fixed; top: 20px; right: 20px; z-index: 10000; min-width: 300px;">
                <i class="${iconMap[type]} mr-2"></i>
                <strong>${message}</strong>
                <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
        `);
        
        $('body').append(notification);
        
        // Animation d'entrée
        notification.hide().fadeIn(300);
        
        // Auto-suppression
        setTimeout(() => {
            notification.fadeOut(300, function() {
                $(this).remove();
            });
        }, duration);
    }
    
    function showSuccessNotification(message) {
        showNotification(message, 'success');
    }
    
    function showWarningNotification(message) {
        showNotification(message, 'warning');
    }
    
    function showErrorNotification(message) {
        showNotification(message, 'error');
    }
    
    // ==========================================================================
    // Amélioration des Sélecteurs
    // ==========================================================================
    
    // Améliorer les select avec des icônes de statut
    function enhanceOrganismSelector() {
        $('#selection_organism option').each(function() {
            const option = $(this);
            const text = option.text();
            
            if (text.includes('✅')) {
                option.attr('data-status', 'available');
            } else if (text.includes('⚪')) {
                option.attr('data-status', 'optional');
            } else if (text.includes('⏳')) {
                option.attr('data-status', 'loading');
            }
        });
    }
    
    // Appliquer les améliorations au chargement
    enhanceOrganismSelector();
    
    // ==========================================================================
    // Gestion des Erreurs
    // ==========================================================================
    
    window.addEventListener('error', function(e) {
        console.error('Erreur JavaScript:', e.error);
        showErrorNotification('Une erreur inattendue s\'est produite');
    });
    
    // ==========================================================================
    // Améliorations des Tableaux
    // ==========================================================================
    
    // Observer l'apparition de nouveaux tableaux DataTables
    const tableObserver = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            if (mutation.type === 'childList') {
                $(mutation.addedNodes).find('.dataTable').each(function() {
                    enhanceDataTable($(this));
                });
            }
        });
    });
    
    tableObserver.observe(document.body, {
        childList: true,
        subtree: true
    });
    
    function enhanceDataTable(table) {
        // Ajouter des animations aux lignes du tableau
        table.find('tbody tr').hover(
            function() {
                $(this).addClass('table-hover-effect');
            },
            function() {
                $(this).removeClass('table-hover-effect');
            }
        );
    }
    
    // CSS pour l'effet hover des tableaux
    $('<style>').text(`
        .table-hover-effect {
            background-color: rgba(52, 152, 219, 0.1) !important;
            transform: scale(1.01);
            transition: all 0.2s ease;
        }
    `).appendTo('head');
    
    // ==========================================================================
    // Amélioration de la Navigation
    // ==========================================================================
    
    // Ajouter des animations aux onglets
    $('.nav-tabs .nav-link').on('click', function() {
        const tab = $(this);
        
        // Animer le changement d'onglet
        $('.tab-content').addClass('fade-out');
        
        setTimeout(() => {
            $('.tab-content').removeClass('fade-out').addClass('fade-in');
        }, 150);
        
        setTimeout(() => {
            $('.tab-content').removeClass('fade-in');
        }, 500);
    });
    
    // CSS pour les animations d'onglets
    $('<style>').text(`
        .fade-out {
            opacity: 0.3;
            transform: translateY(10px);
            transition: all 0.15s ease;
        }
        .fade-in {
            opacity: 1;
            transform: translateY(0);
            transition: all 0.3s ease;
        }
    `).appendTo('head');
    
    // ==========================================================================
    // Gestion du Responsive
    // ==========================================================================
    
    function handleResize() {
        const width = $(window).width();
        
        if (width < 768) {
            // Mode mobile
            $('.sidebar').addClass('mobile-sidebar');
            $('.umap-container').addClass('mobile-umap');
        } else {
            // Mode desktop
            $('.sidebar').removeClass('mobile-sidebar');
            $('.umap-container').removeClass('mobile-umap');
        }
    }
    
    $(window).on('resize', handleResize);
    handleResize(); // Appliquer au chargement
    
    // ==========================================================================
    // Amélioration de l'Accessibilité
    // ==========================================================================
    
    // Ajouter des raccourcis clavier
    $(document).on('keydown', function(e) {
        // Ctrl/Cmd + Enter pour charger le dataset
        if ((e.ctrlKey || e.metaKey) && e.keyCode === 13) {
            $('#import_dataset').click();
        }
        
        // Échap pour fermer les notifications
        if (e.keyCode === 27) {
            $('.notification').fadeOut(300, function() {
                $(this).remove();
            });
        }
    });
    
    // ==========================================================================
    // Fonctions Utilitaires
    // ==========================================================================
    
    // Fonction pour valider les sélections
    function validateSelections() {
        const organism = $('#selection_organism').val();
        const dataset = $('#selection_dataset').val();
        
        const isValid = organism && dataset;
        $('#import_dataset').prop('disabled', !isValid);
        
        if (isValid) {
            $('#import_dataset').removeClass('btn-secondary').addClass('btn-primary');
        } else {
            $('#import_dataset').removeClass('btn-primary').addClass('btn-secondary');
        }
        
        return isValid;
    }
    
    // Observer les changements de sélection
    $('#selection_organism, #selection_dataset').on('change', validateSelections);
    
    // ==========================================================================
    // Initialisation Finale
    // ==========================================================================
    
    console.log("✅ MASLDatlas Interface Enhancement Ready");
    
    // Ajouter une classe pour indiquer que le JS est chargé
    $('body').addClass('js-loaded');
    
    // Animation d'entrée pour les éléments
    $('.well, .card').addClass('fade-in');
    
    // Validation initiale
    validateSelections();
    
    // Message de bienvenue
    setTimeout(() => {
        showNotification('Interface MASLDatlas améliorée chargée avec succès!', 'info', 2000);
    }, 1000);
});

// ==========================================================================
// Fonctions Globales Exportées
// ==========================================================================

window.MASLDInterface = {
    showLoading: showGlobalLoading,
    hideLoading: hideGlobalLoading,
    showSuccess: showSuccessNotification,
    showWarning: showWarningNotification,
    showError: showErrorNotification,
    showInfo: function(message) { showNotification(message, 'info'); }
};
