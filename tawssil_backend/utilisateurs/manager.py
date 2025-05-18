from django.contrib.auth.models import BaseUserManager

class UtilisateurManager(BaseUserManager):
    def create_user(self, username, email, password=None, **extra_fields):
        if not username:
            raise ValueError('اسم المستخدم مطلوب')
        if not email:
            raise ValueError('البريد الإلكتروني مطلوب')
            
        email = self.normalize_email(email)
        user = self.model(username=username, email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(self, username, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        extra_fields.setdefault('type_utilisateur', 'Administrateur')
        
        if extra_fields.get('is_staff') is not True:
            raise ValueError('يجب أن يكون المشرف العام عضوًا في الفريق')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('يجب أن يكون المشرف العام مستخدمًا متميزًا')
        
        return self.create_user(username, email, password, **extra_fields) 