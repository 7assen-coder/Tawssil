from django.shortcuts import render
from rest_framework.decorators import api_view, parser_classes
from rest_framework.response import Response
from .models import Paiement
from django.db.models import Sum
from commandes.models import Commande
from django.utils import timezone
from rest_framework.parsers import JSONParser
from django.db.models.functions import TruncDay, TruncWeek, TruncMonth
from collections import defaultdict

# دوال العرض (views) ستضاف لاحقا

@api_view(['GET'])
def paiements_stats(request):
    total = Paiement.objects.count()
    confirmes = Paiement.objects.filter(statut='Confirme').count()
    attente = Paiement.objects.filter(statut='En Attente').count()
    montant = Paiement.objects.filter(statut='Confirme').aggregate(total=Sum('commande__montant_total'))['total'] or 0
    return Response({
        'total': total,
        'confirmes': confirmes,
        'attente': attente,
        'montant': float(montant)
    })

@api_view(['GET'])
def paiements_list(request):
    paiements = Paiement.objects.select_related('commande', 'commande__client__utilisateur').all().order_by('-id_paiement')
    data = []
    for p in paiements:
        data.append({
            'id': f'PAY-{p.id_paiement:03d}',
            'orderId': f'ORD-{p.commande.id_commande}' if p.commande else '-',
            'customerName': p.commande.client.utilisateur.username if p.commande and p.commande.client and p.commande.client.utilisateur else '-',
            'method': p.methode if p.methode else '-',
            'status': p.statut,
            'amount': float(p.commande.montant_total) if p.commande else 0,
            'date': p.commande.date_commande.strftime('%Y-%m-%d %H:%M') if p.commande and p.commande.date_commande else '-',
            'recu': request.build_absolute_uri(p.recu.url) if p.recu else None,
        })
    return Response(data)

@api_view(['PATCH'])
@parser_classes([JSONParser])
def paiement_update(request, paiement_id):
    try:
        paiement = Paiement.objects.get(id_paiement=int(str(paiement_id).replace('PAY-', '')))
        statut = request.data.get('statut')
        if statut in ['Confirme', 'Echoue']:
            paiement.statut = statut
            paiement.save()
            return Response({'status': 'success', 'new_statut': statut})
        return Response({'status': 'error', 'message': 'Statut non valide'}, status=400)
    except Paiement.DoesNotExist:
        return Response({'status': 'error', 'message': 'Paiement introuvable'}, status=404)
    except Exception as e:
        return Response({'status': 'error', 'message': str(e)}, status=500)

@api_view(['GET'])
def paiements_status_comparaison(request):
    period = request.GET.get('period', 'day')
    if period == 'week':
        trunc = TruncWeek('commande__date_commande')
        label_format = '%Y-%W'
    elif period == 'month':
        trunc = TruncMonth('commande__date_commande')
        label_format = '%Y-%m'
    else:
        trunc = TruncDay('commande__date_commande')
        label_format = '%Y-%m-%d'

    qs = Paiement.objects.select_related('commande').all()
    data = defaultdict(lambda: {'Confirme': 0, 'En Attente': 0, 'Echoue': 0})
    for p in qs:
        date_val = getattr(p.commande.date_commande, 'strftime', lambda x: None)(label_format) if p.commande and p.commande.date_commande else None
        if date_val:
            data[date_val][p.statut] += 1
    # ترتيب حسب التاريخ
    result = [
        {'label': label, **counts}
        for label, counts in sorted(data.items())
    ]
    return Response(result)
