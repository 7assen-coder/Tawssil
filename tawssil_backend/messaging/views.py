from django.shortcuts import render
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from .models import Message
from utilisateurs.models import Utilisateur
from django.db.models import Q
from django.conf import settings
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import JSONParser

# دوال العرض (views) ستضاف لاحقا

@api_view(['GET'])
def support_tickets_count(request):
    clients = Message.objects.filter(expediteur__type_utilisateur='Client')
    chauffeurs = Message.objects.filter(expediteur__type_utilisateur='Chauffeur')
    livreurs = Message.objects.filter(expediteur__type_utilisateur='Livreur')
    data = {
        'total': clients.count() + chauffeurs.count() + livreurs.count(),
        'total_unread': clients.filter(lu=False).count() + chauffeurs.filter(lu=False).count() + livreurs.filter(lu=False).count(),
        'clients': {
            'count': clients.count(),
            'count_unread': clients.filter(lu=False).count(),
            'latest': [
                {
                    'id': m.id,
                    'expediteur': m.expediteur.username,
                    'email': m.expediteur.email,
                    'date': m.date_envoi,
                    'contenu': m.contenu[:40] + ('...' if len(m.contenu) > 40 else '')
                } for m in clients.order_by('-date_envoi')[:3]
            ]
        },
        'chauffeurs': {
            'count': chauffeurs.count(),
            'count_unread': chauffeurs.filter(lu=False).count(),
            'latest': [
                {
                    'id': m.id,
                    'expediteur': m.expediteur.username,
                    'email': m.expediteur.email,
                    'date': m.date_envoi,
                    'contenu': m.contenu[:40] + ('...' if len(m.contenu) > 40 else '')
                } for m in chauffeurs.order_by('-date_envoi')[:3]
            ]
        },
        'livreurs': {
            'count': livreurs.count(),
            'count_unread': livreurs.filter(lu=False).count(),
            'latest': [
                {
                    'id': m.id,
                    'expediteur': m.expediteur.username,
                    'email': m.expediteur.email,
                    'date': m.date_envoi,
                    'contenu': m.contenu[:40] + ('...' if len(m.contenu) > 40 else '')
                } for m in livreurs.order_by('-date_envoi')[:3]
            ]
        }
    }
    return Response(data)

def get_user_avatar(user):
    if hasattr(user, 'photo_profile') and user.photo_profile:
        return settings.MEDIA_URL + str(user.photo_profile)
    return ''

@api_view(['GET'])
def conversations_list(request):
    if not request.user.is_authenticated:
        return Response({'error': 'Authentication required'}, status=401)
    user = request.user
    contacts = Utilisateur.objects.exclude(id_utilisateur=user.id_utilisateur)
    data = []
    for contact in contacts:
        last_msg = Message.objects.filter(
            Q(expediteur=user, destinataire=contact) | Q(expediteur=contact, destinataire=user)
        ).order_by('-date_envoi').first()
        if last_msg:
            data.append({
                'id': contact.id_utilisateur,
                'username': contact.username,
                'type_utilisateur': contact.type_utilisateur,
                'photo_profile': get_user_avatar(contact),
                'email': contact.email,
                'telephone': contact.telephone,
                'lastMessage': last_msg.contenu,
                'lastMessageTime': last_msg.date_envoi.strftime('%H:%M'),
                'unread': Message.objects.filter(expediteur=contact, destinataire=user, lu=False).count(),
            })
    return Response(data)

@api_view(['GET'])
def conversation_messages(request, contact_id):
    if not request.user.is_authenticated:
        return Response({'error': 'Authentication required'}, status=401)
    user = request.user
    contact = Utilisateur.objects.get(id_utilisateur=contact_id)
    messages = Message.objects.filter(
        Q(expediteur=user, destinataire=contact) | Q(expediteur=contact, destinataire=user)
    ).order_by('date_envoi')
    data = [
        {
            'fromMe': msg.expediteur.id_utilisateur == user.id_utilisateur,
            'text': msg.contenu,
            'date': msg.date_envoi.strftime('%d/%m/%Y %H:%M'),
            'read': msg.lu
        }
        for msg in messages
    ]
    return Response(data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_messages_as_read(request, contact_id):
    user = request.user
    contact = Utilisateur.objects.get(id_utilisateur=contact_id)
    updated = Message.objects.filter(expediteur=contact, destinataire=user, lu=False).update(lu=True)
    return Response({'updated': updated})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_message(request, contact_id):
    """
    إرسال رسالة وحفظها في قاعدة البيانات بين المستخدم الحالي وجهة الاتصال
    البيانات المطلوبة: { "contenu": "..." }
    """
    user = request.user
    try:
        contact = Utilisateur.objects.get(id_utilisateur=contact_id)
    except Utilisateur.DoesNotExist:
        return Response({'error': 'Utilisateur non trouvé'}, status=404)
    data = request.data
    contenu = data.get('contenu', '').strip()
    if not contenu:
        return Response({'error': 'Le contenu du message est requis.'}, status=400)
    msg = Message.objects.create(expediteur=user, destinataire=contact, contenu=contenu)
    return Response({
        'id': msg.id,
        'fromMe': True,
        'text': msg.contenu,
        'date': msg.date_envoi.strftime('%d/%m/%Y %H:%M'),
        'read': msg.lu
    }, status=201)
