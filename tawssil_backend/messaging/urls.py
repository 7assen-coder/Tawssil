from django.urls import path
from . import views

app_name = 'messaging'
 
urlpatterns = [
    # هنا يمكن إضافة مسارات API للرسائل
    path('support-tickets-count/', views.support_tickets_count, name='support_tickets_count'),
    path('conversations/', views.conversations_list, name='conversations_list'),
    path('conversations/<int:contact_id>/messages/', views.conversation_messages, name='conversation_messages'),
    path('conversations/<int:contact_id>/mark-read/', views.mark_messages_as_read, name='mark_messages_as_read'),
    path('conversations/<int:contact_id>/send/', views.send_message, name='send_message'),
] 