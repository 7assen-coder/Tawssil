from django.urls import path
from . import views

app_name = 'paiements'
 
urlpatterns = [
    # هنا يمكن إضافة مسارات API للمدفوعات
    path('stats/', views.paiements_stats, name='paiements_stats'),
    path('list/', views.paiements_list, name='paiements_list'),
    path('<str:paiement_id>/update/', views.paiement_update, name='paiement_update'),
    path('status-comparaison/', views.paiements_status_comparaison, name='paiements_status_comparaison'),
] 