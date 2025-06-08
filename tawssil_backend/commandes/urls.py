from django.urls import path
from . import views

app_name = 'commandes'

urlpatterns = [
    # هنا يمكن إضافة مسارات API للطلبات
    path('active-deliveries-count/', views.active_deliveries_count, name='active_deliveries_count'),
    path('last-month-active-deliveries-count/', views.last_month_active_deliveries_count, name='last_month_active_deliveries_count'),
    path('today-revenue/', views.today_revenue, name='today_revenue'),
    path('yesterday-revenue/', views.yesterday_revenue, name='yesterday_revenue'),
    path('recent-chauffeur-demandes/', views.recent_chauffeur_demandes, name='recent_chauffeur_demandes'),
    path('recent-livreur-livraisons/', views.recent_livreur_livraisons, name='recent_livreur_livraisons'),
    path('recent-voyages/', views.recent_voyages, name='recent_voyages'),
    path('commandes-stats/', views.commandes_stats, name='commandes_stats'),
    path('commandes-list/', views.commandes_list, name='commandes_list'),
    path('voyages-list/', views.voyages_list, name='voyages_list'),
    path('providers/<int:provider_id>/orders/', views.commandes_by_provider, name='commandes_by_provider'),
] 