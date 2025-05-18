from django.apps import AppConfig


class CommandesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'commandes'
    
    def ready(self):
        import commandes.signals