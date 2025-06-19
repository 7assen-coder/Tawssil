from django.shortcuts import render
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Commande, LigneCommande, Colis, Voyage
from django.utils import timezone
from datetime import timedelta
from django.db.models import Sum, F, Q
from rest_framework import serializers
from utilisateurs.models import Utilisateur, Client, Fournisseur, Livreur, Chauffeur


# دوال العرض (views) ستضاف لاحقا

@api_view(['GET'])
def active_deliveries_count(request):
    try:
        count = Commande.objects.filter(
            Q(statut__icontains='accept') |
            Q(statut__icontains='prépar') |
            Q(statut__icontains='livraison')
        ).count()
        return Response({'active_deliveries': count})
    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def last_month_active_deliveries_count(request):
    now = timezone.now()
    first_day_this_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    last_month_end = first_day_this_month - timedelta(seconds=1)
    last_month_start = last_month_end.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    count = Commande.objects.filter(
        statut='En livraison',
        date_commande__gte=last_month_start,
        date_commande__lte=last_month_end
    ).count()
    return Response({'last_month_active_deliveries': count})

@api_view(['GET'])
def today_revenue(request):
    now = timezone.localtime()
    start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
    commandes = Commande.objects.filter(
        statut='Livrée',
        date_commande__gte=start_of_day,
        date_commande__lte=now
    )
    total_montant = commandes.aggregate(total=Sum('montant_total'))['total'] or 0
    total_frais = commandes.aggregate(total=Sum('frais_livraison'))['total'] or 0
    revenue = float(total_montant) - float(total_frais)
    return Response({'today_revenue': revenue})

@api_view(['GET'])
def yesterday_revenue(request):
    yesterday = timezone.now().date() - timedelta(days=1)
    total = Commande.objects.filter(
        statut='Livrée',
        date_commande__date=yesterday
    ).aggregate(
        revenue=Sum(F('montant_total') - F('frais_livraison'))
    )['revenue'] or 0
    return Response({'yesterday_revenue': float(total)})

class CommandeRecentSerializer(serializers.ModelSerializer):
    chauffeur_username = serializers.SerializerMethodField()
    client_username = serializers.SerializerMethodField()
    class Meta:
        model = Commande
        fields = ['id_commande', 'chauffeur_username', 'client_username', 'date_commande', 'adresse_livraison', 'montant_total', 'statut']
    def get_chauffeur_username(self, obj):
        return obj.chauffeur.utilisateur.username if obj.chauffeur and obj.chauffeur.utilisateur else None
    def get_client_username(self, obj):
        return obj.client.utilisateur.username if obj.client and obj.client.utilisateur else None

@api_view(['GET'])
def recent_chauffeur_demandes(request):
    commandes = Commande.objects.filter(chauffeur__isnull=False).order_by('-date_commande')[:10]
    serializer = CommandeRecentSerializer(commandes, many=True)
    return Response(serializer.data)

class CommandeRecentLivreurSerializer(serializers.ModelSerializer):
    livreur_username = serializers.SerializerMethodField()
    client_username = serializers.SerializerMethodField()
    class Meta:
        model = Commande
        fields = ['id_commande', 'livreur_username', 'client_username', 'date_commande', 'adresse_livraison', 'montant_total', 'statut']
    def get_livreur_username(self, obj):
        return obj.livreur.utilisateur.username if obj.livreur and obj.livreur.utilisateur else None
    def get_client_username(self, obj):
        return obj.client.utilisateur.username if obj.client and obj.client.utilisateur else None

@api_view(['GET'])
def recent_livreur_livraisons(request):
    commandes = Commande.objects.filter(livreur__isnull=False).order_by('-date_commande')[:10]
    serializer = CommandeRecentLivreurSerializer(commandes, many=True)
    return Response(serializer.data)

class VoyageRecentSerializer(serializers.ModelSerializer):
    voyageur_username = serializers.SerializerMethodField()
    class Meta:
        model = Voyage
        fields = ['id_voyage', 'voyageur_username', 'destination', 'tarif_transport', 'poids_disponible', 'date_depart']
    def get_voyageur_username(self, obj):
        return obj.voyageur.utilisateur.username if obj.voyageur and obj.voyageur.utilisateur else None

@api_view(['GET'])
def recent_voyages(request):
    voyages = Voyage.objects.order_by('-date_depart')[:10]
    serializer = VoyageRecentSerializer(voyages, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def commandes_stats(request):
    total_commandes = Commande.objects.count()
    total_clients = Utilisateur.objects.filter(type_utilisateur='Client').count()
    moyenne = (total_commandes / total_clients) if total_clients > 0 else 0
    return Response({
        'total_commandes': total_commandes,
        'total_clients': total_clients,
        'moyenne': round(moyenne, 2)
    })

class CommandeFullSerializer(serializers.ModelSerializer):
    client_username = serializers.SerializerMethodField()
    fournisseur_nom = serializers.SerializerMethodField()
    livreur_username = serializers.SerializerMethodField()
    chauffeur_username = serializers.SerializerMethodField()
    evaluation = serializers.SerializerMethodField()
    
    class Meta:
        model = Commande
        fields = [
            'id_commande', 'client_username', 'fournisseur_nom', 'livreur_username', 'chauffeur_username',
            'date_commande', 'adresse_livraison', 'montant_total', 'frais_livraison',
            'statut', 'instructions_speciales', 'date_livraison_estimee', 'date_livraison_reelle', 'evaluation'
        ]
        
    def get_client_username(self, obj):
        return obj.client.utilisateur.username if obj.client and obj.client.utilisateur else ''
        
    def get_fournisseur_nom(self, obj):
        return obj.fournisseur.nom_commerce if obj.fournisseur else ''
        
    def get_livreur_username(self, obj):
        return obj.livreur.utilisateur.username if obj.livreur and obj.livreur.utilisateur else ''
        
    def get_chauffeur_username(self, obj):
        return obj.chauffeur.utilisateur.username if obj.chauffeur and obj.chauffeur.utilisateur else ''
    
    def get_evaluation(self, obj):
        # استخدام جدول التقييمات للحصول على متوسط التقييم للتوصيلة
        from evaluations.models import Evaluation
        from django.db.models import Avg
        
        try:
            # البحث عن التقييمات المرتبطة بهذه التوصيلة
            evaluation = Evaluation.objects.filter(commande=obj).first()
            if evaluation:
                return evaluation.note
            return None
        except Exception:
            return None

@api_view(['GET'])
def commandes_list(request):
    commandes = Commande.objects.all().order_by('-date_commande')
    serializer = CommandeFullSerializer(commandes, many=True)
    return Response(serializer.data)

class VoyageFullSerializer(serializers.ModelSerializer):
    voyageur_username = serializers.SerializerMethodField()
    chauffeur_username = serializers.SerializerMethodField()
    nombre_personnes = serializers.SerializerMethodField()
    evaluation = serializers.SerializerMethodField()
    class Meta:
        model = Voyage
        fields = [
            'id_voyage', 'voyageur_username', 'chauffeur_username', 'destination', 'date_depart', 'date_arrivee',
            'nombre_personnes', 'tarif_transport', 'statut', 'evaluation'
        ]
    def get_voyageur_username(self, obj):
        return obj.voyageur.utilisateur.username if obj.voyageur and obj.voyageur.utilisateur else ''
    def get_chauffeur_username(self, obj):
        return obj.chauffeur.utilisateur.username if obj.chauffeur and obj.chauffeur.utilisateur else ''
    def get_nombre_personnes(self, obj):
        return obj.poids_disponible
    def get_evaluation(self, obj):
        return obj.rating if obj.rating is not None else None

@api_view(['GET'])
def voyages_list(request):
    voyages = Voyage.objects.all().order_by('-date_depart')
    serializer = VoyageFullSerializer(voyages, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def commandes_by_provider(request, provider_id):
    try:
        fournisseur = Fournisseur.objects.get(id=provider_id)
        commandes = Commande.objects.filter(fournisseur=fournisseur).order_by('-date_commande')
        serializer = CommandeFullSerializer(commandes, many=True)
        return Response({'orders': serializer.data})
    except Fournisseur.DoesNotExist:
        return Response({'orders': []}, status=404)

# دالة جديدة للحصول على عدد التوصيلات للموصل
@api_view(['GET'])
def livreur_commandes_count(request, livreur_id):
    """
    الحصول على عدد التوصيلات للموصل (جميع الحالات)
    """
    try:
        # البحث عن المستخدم أولاً
        print(f"البحث عن المستخدم بمعرف: {livreur_id}")
        utilisateur = Utilisateur.objects.get(id_utilisateur=livreur_id)
        print(f"تم العثور على المستخدم: {utilisateur.username}, نوع: {utilisateur.type_utilisateur}")
        
        # التحقق من أن المستخدم هو موصل
        if utilisateur.type_utilisateur != 'Livreur':
            print(f"المستخدم ليس موصلاً، نوعه: {utilisateur.type_utilisateur}")
            return Response({'error': 'المستخدم ليس موصلاً'}, status=400)
            
        # البحث عن ملف تعريف الموصل
        try:
            livreur = Livreur.objects.get(utilisateur=utilisateur)
            print(f"تم العثور على ملف تعريف الموصل بمعرف: {livreur.id}")
        except Livreur.DoesNotExist:
            print("لم يتم العثور على ملف تعريف الموصل")
            return Response({'count': 0}, status=200)
            
        # حساب عدد جميع التوصيلات بغض النظر عن حالتها
        count = Commande.objects.filter(livreur=livreur).count()
        print(f"عدد التوصيلات للموصل: {count}")
        
        return Response({'count': count}, status=200)
        
    except Utilisateur.DoesNotExist:
        print(f"لم يتم العثور على مستخدم بمعرف: {livreur_id}")
        return Response({'error': 'المستخدم غير موجود'}, status=404)
    except Exception as e:
        print(f"خطأ: {str(e)}")
        return Response({'error': str(e)}, status=500)

# دالة جديدة للحصول على عدد الرحلات للسائق
@api_view(['GET'])
def chauffeur_voyages_count(request, chauffeur_id):
    """
    الحصول على عدد الرحلات والطلبات للسائق (جميع الحالات)
    """
    try:
        # البحث عن المستخدم أولاً
        print(f"البحث عن المستخدم بمعرف: {chauffeur_id}")
        utilisateur = Utilisateur.objects.get(id_utilisateur=chauffeur_id)
        print(f"تم العثور على المستخدم: {utilisateur.username}, نوع: {utilisateur.type_utilisateur}")
        
        # التحقق من أن المستخدم هو سائق
        if utilisateur.type_utilisateur != 'Chauffeur':
            print(f"المستخدم ليس سائقاً، نوعه: {utilisateur.type_utilisateur}")
            return Response({'error': 'المستخدم ليس سائقاً'}, status=400)
            
        # البحث عن ملف تعريف السائق
        try:
            chauffeur = Chauffeur.objects.get(utilisateur=utilisateur)
            print(f"تم العثور على ملف تعريف السائق بمعرف: {chauffeur.id}")
        except Chauffeur.DoesNotExist:
            print("لم يتم العثور على ملف تعريف السائق")
            return Response({'count': 0}, status=200)
            
        # حساب عدد جميع الرحلات بغض النظر عن حالتها
        voyages_count = Voyage.objects.filter(chauffeur=chauffeur).count()
        print(f"عدد الرحلات للسائق: {voyages_count}")
        
        # حساب عدد جميع الطلبات بغض النظر عن حالتها
        commandes_count = Commande.objects.filter(chauffeur=chauffeur).count()
        print(f"عدد الطلبات للسائق: {commandes_count}")
        
        # إجمالي عدد الرحلات والطلبات
        total_count = voyages_count + commandes_count
        print(f"إجمالي عدد الرحلات والطلبات للسائق: {total_count}")
        
        return Response({'count': total_count}, status=200)
        
    except Utilisateur.DoesNotExist:
        print(f"لم يتم العثور على مستخدم بمعرف: {chauffeur_id}")
        return Response({'error': 'المستخدم غير موجود'}, status=404)
    except Exception as e:
        print(f"خطأ: {str(e)}")
        return Response({'error': str(e)}, status=500)

# دالة جديدة للحصول على متوسط تقييم الموصل أو السائق
@api_view(['GET'])
def get_user_rating(request, user_id):
    """
    الحصول على متوسط تقييم الموصل أو السائق بناءً على نوع المستخدم
    """
    try:
        # البحث عن المستخدم أولاً
        print(f"البحث عن المستخدم بمعرف: {user_id}")
        utilisateur = Utilisateur.objects.get(id_utilisateur=user_id)
        print(f"تم العثور على المستخدم: {utilisateur.username}, نوع: {utilisateur.type_utilisateur}")
        
        user_type = utilisateur.type_utilisateur
        rating = 0.0
        
        # حساب متوسط التقييم حسب نوع المستخدم
        if user_type == 'Livreur':
            # للموصلين: متوسط تقييم الطلبات المكتملة
            try:
                livreur = Livreur.objects.get(utilisateur=utilisateur)
                print(f"تم العثور على ملف تعريف الموصل بمعرف: {livreur.id}")
                
                # استخدام جدول التقييمات للحصول على متوسط التقييم
                from evaluations.models import Evaluation
                from django.db.models import Avg
                
                # الحصول على التقييمات للموصل
                evaluations = Evaluation.objects.filter(livreur=livreur)
                
                if evaluations.exists():
                    # حساب متوسط التقييمات
                    avg_rating = evaluations.aggregate(Avg('note'))['note__avg']
                    rating = avg_rating
                    print(f"متوسط تقييم الموصل من جدول التقييمات: {rating}")
                else:
                    # استخدام قيمة ثابتة للتقييم إذا لم تكن هناك تقييمات
                    rating = 4.5
                    print(f"لا توجد تقييمات للموصل، استخدام قيمة ثابتة: {rating}")
                
                # استخدام note_moyenne من نموذج Livreur إذا كانت متوفرة
                if livreur.note_moyenne > 0:
                    rating = livreur.note_moyenne
                    print(f"استخدام متوسط التقييم المخزن في نموذج الموصل: {rating}")
            except Livreur.DoesNotExist:
                print("لم يتم العثور على ملف تعريف الموصل")
                return Response({'rating': 0.0}, status=200)
                
        elif user_type == 'Chauffeur':
            # للسائقين: متوسط تقييم الرحلات المكتملة
            try:
                chauffeur = Chauffeur.objects.get(utilisateur=utilisateur)
                print(f"تم العثور على ملف تعريف السائق بمعرف: {chauffeur.id}")
                
                # الحصول على جميع الرحلات المكتملة
                completed_voyages = Voyage.objects.filter(
                    chauffeur=chauffeur,
                    statut='Terminée'
                )
                
                # حساب عدد الرحلات المكتملة
                completed_count = completed_voyages.count()
                print(f"عدد الرحلات المكتملة للسائق: {completed_count}")
                
                if completed_count > 0:
                    # حساب مجموع التقييمات من حقل rating في نموذج الرحلة
                    # نستبعد الرحلات التي ليس لها تقييم
                    rated_voyages = completed_voyages.exclude(rating__isnull=True)
                    rated_count = rated_voyages.count()
                    
                    if rated_count > 0:
                        total_rating = sum(voyage.rating for voyage in rated_voyages if voyage.rating is not None)
                        rating = total_rating / rated_count
                        print(f"متوسط تقييم السائق: {rating}")
                    else:
                        # استخدام قيمة ثابتة للتقييم إذا لم تكن هناك رحلات مقيمة
                        rating = 4.7
                        print(f"متوسط تقييم السائق (قيمة ثابتة): {rating}")
                else:
                    # استخدام قيمة ثابتة للتقييم إذا لم تكن هناك رحلات مكتملة
                    rating = 4.7
                    print(f"متوسط تقييم السائق (قيمة ثابتة): {rating}")
            except Chauffeur.DoesNotExist:
                print("لم يتم العثور على ملف تعريف السائق")
                return Response({'rating': 0.0}, status=200)
        else:
            print(f"نوع مستخدم غير مدعوم: {user_type}")
            return Response({'error': 'نوع مستخدم غير مدعوم'}, status=400)
        
        # تقريب التقييم إلى رقم عشري واحد
        rating = round(rating, 1)
        return Response({'rating': rating}, status=200)
        
    except Utilisateur.DoesNotExist:
        print(f"لم يتم العثور على مستخدم بمعرف: {user_id}")
        return Response({'error': 'المستخدم غير موجود'}, status=404)
    except Exception as e:
        print(f"خطأ: {str(e)}")
        return Response({'error': str(e)}, status=500)

# دالة جديدة لحساب الأرباح بناءً على عدد التوصيلات أو الرحلات المكتملة فقط
@api_view(['GET'])
def get_user_earnings(request, user_id):
    """
    حساب الأرباح للموصل أو السائق بناءً على عدد التوصيلات أو الرحلات المكتملة فقط
    الأرباح = عدد التوصيلات/الرحلات × 100 UM
    """
    try:
        # البحث عن المستخدم أولاً
        print(f"البحث عن المستخدم لحساب الأرباح بمعرف: {user_id}")
        utilisateur = Utilisateur.objects.get(id_utilisateur=user_id)
        print(f"تم العثور على المستخدم: {utilisateur.username}, نوع: {utilisateur.type_utilisateur}")
        
        user_type = utilisateur.type_utilisateur
        count = 0
        earnings = 0
        
        # حساب الأرباح حسب نوع المستخدم
        if user_type == 'Livreur':
            # للموصلين: عدد التوصيلات المكتملة × 100 UM
            try:
                livreur = Livreur.objects.get(utilisateur=utilisateur)
                print(f"تم العثور على ملف تعريف الموصل بمعرف: {livreur.id}")
                
                # حساب عدد التوصيلات المكتملة فقط (statut='Livrée')
                count = Commande.objects.filter(livreur=livreur, statut='Livrée').count()
                print(f"عدد التوصيلات المكتملة للموصل: {count}")
                
                # حساب الأرباح
                earnings = count * 100
                print(f"أرباح الموصل: {earnings} UM")
                
            except Livreur.DoesNotExist:
                print("لم يتم العثور على ملف تعريف الموصل")
                return Response({'earnings': 0}, status=200)
                
        elif user_type == 'Chauffeur':
            # للسائقين: عدد الرحلات المكتملة × 100 UM
            try:
                chauffeur = Chauffeur.objects.get(utilisateur=utilisateur)
                print(f"تم العثور على ملف تعريف السائق بمعرف: {chauffeur.id}")
                
                # حساب عدد الرحلات المكتملة فقط (statut='Terminée')
                voyages_count = Voyage.objects.filter(chauffeur=chauffeur, statut='Terminée').count()
                print(f"عدد الرحلات المكتملة للسائق: {voyages_count}")
                
                # حساب عدد الطلبات المكتملة فقط (statut='Livrée')
                commandes_count = Commande.objects.filter(chauffeur=chauffeur, statut='Livrée').count()
                print(f"عدد الطلبات المكتملة للسائق: {commandes_count}")
                
                # إجمالي عدد الرحلات والطلبات المكتملة
                count = voyages_count + commandes_count
                print(f"إجمالي عدد الرحلات والطلبات المكتملة للسائق: {count}")
                
                # حساب الأرباح
                earnings = count * 100
                print(f"أرباح السائق: {earnings} UM")
                
            except Chauffeur.DoesNotExist:
                print("لم يتم العثور على ملف تعريف السائق")
                return Response({'earnings': 0}, status=200)
        else:
            print(f"نوع مستخدم غير مدعوم: {user_type}")
            return Response({'error': 'نوع مستخدم غير مدعوم'}, status=400)
        
        return Response({'earnings': earnings}, status=200)
        
    except Utilisateur.DoesNotExist:
        print(f"لم يتم العثور على مستخدم بمعرف: {user_id}")
        return Response({'error': 'المستخدم غير موجود'}, status=404)
    except Exception as e:
        print(f"خطأ: {str(e)}")
        return Response({'error': str(e)}, status=500)
