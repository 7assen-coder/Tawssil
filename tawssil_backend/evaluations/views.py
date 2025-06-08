from django.shortcuts import render
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Evaluation
from django.db.models import Avg, Count, Sum
from utilisateurs.models import Client

# دوال العرض (views) ستضاف لاحقا

@api_view(['GET'])
def clients_average_rating(request):
    # مجموع كل التقييمات
    total_notes = Evaluation.objects.aggregate(total=Sum('note'))['total'] or 0
    # عدد العملاء الذين قاموا بأي تقييم
    clients_with_eval = Evaluation.objects.values('client').aggregate(count=Count('client'))['count'] or 0
    moyenne = (total_notes / clients_with_eval) if clients_with_eval > 0 else 0
    return Response({
        'note_moyenne': round(moyenne, 2),
        'total_evaluations': Evaluation.objects.count(),
        'clients_with_evaluation': clients_with_eval
    })
