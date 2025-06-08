from django.urls import path
from . import views

app_name = 'produits'

urlpatterns = [
    path('providers/<int:provider_id>/products/', views.products_by_provider, name='products_by_provider'),
    path('create/', views.create_product, name='create_product'),
    path('<int:product_id>/update/', views.update_product, name='update_product'),
    path('<int:product_id>/delete/', views.delete_product, name='delete_product'),
    # هنا يمكن إضافة مسارات API للمنتجات
] 