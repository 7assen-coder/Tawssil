from django.urls import path
from . import views

app_name = 'evaluations'

urlpatterns = [
    path('clients-average-rating/', views.clients_average_rating, name='clients_average_rating'),
    # هنا يمكن إضافة مسارات API للتقييمات
] 