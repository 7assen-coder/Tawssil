import os
import sys
import django

# إعداد بيئة Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'tawssil_backend.settings')
django.setup()

from utilisateurs.models import Utilisateur

def check_database():
    # عدد جميع المستخدمين
    all_users = Utilisateur.objects.all()
    print(f"إجمالي عدد المستخدمين: {all_users.count()}")
    
    # المستخدمين الذين يحتوي اسمهم على 'test'
    test_users = Utilisateur.objects.filter(nom__icontains='test')
    print(f"\nالمستخدمين الذين يحتوي اسمهم على 'test': {test_users.count()}")
    
    for user in test_users:
        print(f"ID: {user.id_utilisateur}, الاسم: {user.nom}, البريد: {user.email}, النوع: {user.type_utilisateur}")
    
    # المستخدمين من نوع 'Administrateur'
    admin_users = Utilisateur.objects.filter(type_utilisateur='Administrateur')
    print(f"\nالمستخدمين من نوع 'Administrateur': {admin_users.count()}")
    
    for user in admin_users:
        print(f"ID: {user.id_utilisateur}, الاسم: {user.nom}, البريد: {user.email}, النوع: {user.type_utilisateur}")
    
    # التحقق مباشر باستخدام Q objects
    from django.db.models import Q
    query = Q(nom__icontains='test')
    direct_query_users = Utilisateur.objects.filter(query)
    print(f"\nالمستخدمين من استعلام مباشر Q(nom__icontains='test'): {direct_query_users.count()}")
    
    for user in direct_query_users:
        print(f"ID: {user.id_utilisateur}, الاسم: {user.nom}, البريد: {user.email}, النوع: {user.type_utilisateur}")

if __name__ == "__main__":
    check_database() 