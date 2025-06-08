from django.shortcuts import render
from rest_framework.decorators import api_view, parser_classes
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from .models import Produit
from utilisateurs.models import Fournisseur
from .serializers import ProduitSerializer

@api_view(['GET'])
def products_by_provider(request, provider_id):
    try:
        fournisseur = Fournisseur.objects.get(id=provider_id)
        produits = Produit.objects.filter(fournisseur=fournisseur)
        serializer = ProduitSerializer(produits, many=True, context={'request': request})
        return Response(serializer.data)
    except Fournisseur.DoesNotExist:
        return Response([], status=404)

@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def create_product(request):
    try:
        data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
        fournisseur_id = data.get('fournisseur')
        if not fournisseur_id:
            return Response({'status': 'error', 'message': 'Fournisseur requis.'}, status=400)
        try:
            fournisseur = Fournisseur.objects.get(id=fournisseur_id)
        except Fournisseur.DoesNotExist:
            return Response({'status': 'error', 'message': 'Fournisseur introuvable.'}, status=404)
        produit_data = data
        produit_data['fournisseur'] = fournisseur.id
        serializer = ProduitSerializer(data=produit_data)
        if serializer.is_valid():
            produit = serializer.save()
            # إضافة الصورة إذا تم رفعها
            if 'image' in request.FILES:
                produit.image = request.FILES['image']
                produit.save()
            return Response(ProduitSerializer(produit, context={'request': request}).data, status=201)
        else:
            return Response({'status': 'error', 'message': 'Données invalides', 'errors': serializer.errors}, status=400)
    except Exception as e:
        return Response({'status': 'error', 'message': str(e)}, status=500)

@api_view(['PUT', 'PATCH'])
@parser_classes([MultiPartParser, FormParser])
def update_product(request, product_id):
    try:
        try:
            produit = Produit.objects.get(id=product_id)
        except Produit.DoesNotExist:
            return Response({'status': 'error', 'message': 'Produit introuvable.'}, status=404)
        data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
        # تحقق من أن المزود لم يتغير
        fournisseur_id = data.get('fournisseur')
        if fournisseur_id and int(fournisseur_id) != produit.fournisseur.id:
            return Response({'status': 'error', 'message': 'Changement de fournisseur non autorisé.'}, status=400)
        serializer = ProduitSerializer(produit, data=data, partial=True)
        if serializer.is_valid():
            produit = serializer.save()
            if 'image' in request.FILES:
                produit.image = request.FILES['image']
                produit.save()
            return Response(ProduitSerializer(produit, context={'request': request}).data)
        else:
            return Response({'status': 'error', 'message': 'Données invalides', 'errors': serializer.errors}, status=400)
    except Exception as e:
        return Response({'status': 'error', 'message': str(e)}, status=500)

@api_view(['DELETE'])
def delete_product(request, product_id):
    try:
        try:
            produit = Produit.objects.get(id=product_id)
        except Produit.DoesNotExist:
            return Response({'status': 'error', 'message': 'Produit introuvable.'}, status=404)
        produit.delete()
        return Response({'status': 'success', 'message': 'Produit supprimé avec succès.'})
    except Exception as e:
        return Response({'status': 'error', 'message': str(e)}, status=500)

# دوال العرض (views) ستضاف لاحقا
