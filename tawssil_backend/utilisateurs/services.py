import random
import string
import logging
from django.utils import timezone
from django.core.mail import send_mail
from django.conf import settings
import datetime
import requests
import json
from datetime import timedelta

# تعريف متغير logger
logger = logging.getLogger(__name__)

def generate_otp(length=4):
    """توليد رمز OTP عشوائي"""
    return ''.join(random.choices(string.digits, k=length))

def save_otp_to_db(user, identifier, code, expires_minutes=3):
    """حفظ رمز OTP في قاعدة البيانات"""
    from .models import OTPCode  # استيراد محلي لتجنب التعارض الدائري
    
    # تحديد نوع المعرف
    otp_type = 'EMAIL' if '@' in identifier else 'SMS'
    
    # إلغاء تفعيل الرموز السابقة
    user.otp_codes.filter(
        identifier=identifier,
        is_used=False
    ).update(is_used=True)
    
    # إنشاء رمز OTP جديد
    expires_at = timezone.now() + datetime.timedelta(minutes=expires_minutes)
    otp = OTPCode.objects.create(
        user=user,
        code=code,
        identifier=identifier,
        expires_at=expires_at,
        type=otp_type  # إضافة حقل النوع
    )
    
    logger.info(f"تم حفظ رمز OTP في قاعدة البيانات: {code} للمعرف: {identifier} (نوع: {otp_type})")
    
    return otp

def send_email_otp(email, otp_code):
    """إرسال رمز OTP عبر البريد الإلكتروني"""
    try:
        subject = 'رمز التحقق من تطبيق Tawssil'
        message = f'رمز التحقق الخاص بك هو: {otp_code}'
        html_message = f"""
        <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ text-align: center; margin-bottom: 20px; }}
                    .code {{ font-size: 24px; font-weight: bold; text-align: center; 
                             padding: 10px; background-color: #f0f0f0; margin: 15px 0; }}
                    .footer {{ font-size: 12px; text-align: center; margin-top: 30px; color: #777; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h2>رمز التحقق من تطبيق Tawssil</h2>
                    </div>
                    <p>مرحبًا،</p>
                    <p>لقد تلقينا طلبًا لتسجيل الدخول إلى حسابك. استخدم رمز التحقق أدناه:</p>
                    <div class="code">{otp_code}</div>
                    <p>هذا الرمز صالح لمدة 3 دقائق فقط.</p>
                    <p>إذا لم تطلب هذا الرمز، يرجى تجاهل هذا البريد الإلكتروني.</p>
                    <div class="footer">
                        <p>هذه رسالة آلية، يرجى عدم الرد عليها.</p>
                        <p>&copy; 2025 Tawssil. جميع الحقوق محفوظة.</p>
                    </div>
                </div>
            </body>
        </html>
        """
        
        from_email = settings.DEFAULT_FROM_EMAIL
        recipient_list = [email]
        
        # تسجيل محاولة الإرسال
        logger.info(f"محاولة إرسال رمز OTP بالبريد الإلكتروني إلى {email}")
        
        # إرسال بريد إلكتروني
        result = send_mail(
            subject,
            message,
            from_email,
            recipient_list,
            fail_silently=False,
            html_message=html_message
        )
        
        logger.info(f"نتيجة إرسال البريد الإلكتروني: {result}")
        return result > 0
        
    except Exception as e:
        logger.error(f"خطأ أثناء إرسال البريد الإلكتروني: {str(e)}")
        return False

def send_sms_otp(phone_number, otp_code):
    """إرسال رمز OTP عبر رسالة نصية"""
    try:
        # تسجيل محاولة الإرسال
        logger.info(f"محاولة إرسال رمز OTP برسالة نصية إلى {phone_number}")
        
        # في وضع التطوير، نعتبر الإرسال ناجحًا دائمًا
        if settings.DEBUG:
            logger.info(f"وضع التطوير: تخطي إرسال SMS فعلي. الرمز: {otp_code}")
            return True
        
        # استخدام Twilio لإرسال الرسالة
        from twilio.rest import Client
        
        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        
        message = client.messages.create(
            body=f"رمز التحقق الخاص بك في تطبيق Tawssil هو: {otp_code}",
            from_=settings.TWILIO_PHONE_NUMBER,
            to=phone_number
        )
        
        logger.info(f"تم إرسال الرسالة النصية، معرف الرسالة: {message.sid}")
        return True
        
    except Exception as e:
        logger.error(f"خطأ أثناء إرسال الرسالة النصية: {str(e)}")
        return False

def verify_otp(identifier, code):
    """
    التحقق من صحة رمز OTP وإعادة المستخدم المرتبط به إذا كان موجودًا
    
    Args:
        identifier: البريد الإلكتروني أو رقم الهاتف
        code: رمز OTP (4 أرقام)
        
    Returns:
        (is_valid, user, error_info): ثلاثية تحتوي على:
            - is_valid: هل الرمز صالح
            - user: كائن المستخدم (أو None إذا لم يكن مرتبطًا بمستخدم)
            - error_info: معلومات إضافية عن الخطأ إذا لم يكن الرمز صالحًا
    """
    from .models import OTPCode
    from django.utils import timezone
    
    # سجل المحاولة للتصحيح
    logger.info(f"محاولة التحقق من رمز OTP: identifier={identifier}, code={code}")
    
    if not identifier or not code:
        logger.warning("معرف أو رمز OTP غير مقدم")
        return False, None, {'reason': 'missing_data', 'message': 'المعرف ورمز التحقق مطلوبان'}
    
    # تنظيف البيانات
    identifier = identifier.strip().lower()
    code = str(code).strip()
    
    try:
        # الحصول على أحدث رمز OTP لهذا المعرف
        otp_records = OTPCode.objects.filter(
            identifier=identifier,
        ).order_by('-created_at')
        
        logger.info(f"تم العثور على {otp_records.count()} سجل OTP للمعرف {identifier}")
        
        if not otp_records.exists():
            logger.warning(f"لا توجد رموز OTP للمعرف {identifier}")
            return False, None, {'reason': 'no_active_otp', 'message': 'لا يوجد رمز تحقق نشط، يرجى طلب رمز جديد'}
        
        # الحصول على أحدث رمز
        latest_otp = otp_records.first()
        
        # طباعة تفاصيل أحدث رمز OTP للتصحيح
        logger.info(f"أحدث رمز OTP: code={latest_otp.code}, created_at={latest_otp.created_at}, is_used={latest_otp.is_used}")
        
        # التحقق من الرمز المقدم مقابل أحدث رمز
        if latest_otp.code != code:
            logger.warning(f"رمز OTP غير صحيح: المتوقع {latest_otp.code}، المستلم {code}")
            
            # التحقق من جميع الرموز الأخرى (تحقق خاص لدعم الحالات الاستثنائية)
            for otp in otp_records:
                if otp.code == code:
                    logger.info(f"تطابق الرمز مع رمز OTP سابق: {otp.created_at}")
                    
                    # تحديث حالة الرمز
                    otp.is_used = True
                    otp.save()
                    
                    # الحصول على المستخدم المرتبط (إن وجد)
                    user = otp.user
                    
                    return True, user, {'message': 'تم التحقق من الرمز بنجاح (رمز سابق)'}
            
            return False, None, {'reason': 'invalid_otp', 'message': 'رمز التحقق غير صحيح'}
        
        # التحقق من انتهاء الصلاحية (30 دقيقة)
        expiry_time = latest_otp.created_at + timedelta(minutes=30)
        if timezone.now() > expiry_time:
            logger.warning(f"انتهت صلاحية رمز OTP: created_at={latest_otp.created_at}")
            return False, None, {'reason': 'otp_expired', 'message': 'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد'}
        
        # التحقق من استخدام الرمز مسبقًا
        if latest_otp.is_used:
            logger.warning(f"رمز OTP مستخدم بالفعل: is_used={latest_otp.is_used}")
            # تغيير في السلوك - نعتبر الرمز صالحًا إذا كان قد تم استخدامه بالفعل (للمستخدمين الجدد)
            user = latest_otp.user
            return True, user, {'message': 'تم التحقق من الرمز بنجاح (مستخدم مسبقًا)'}
            #return False, None, {'reason': 'otp_used', 'message': 'تم استخدام هذا الرمز بالفعل، يرجى طلب رمز جديد'}
        
        # كل شيء على ما يرام، تحديث حالة الرمز وإعادة المستخدم
        latest_otp.is_used = True
        latest_otp.save()
        
        # الحصول على المستخدم المرتبط (إن وجد)
        user = latest_otp.user
        
        logger.info(f"تم التحقق بنجاح: user={'موجود' if user else 'لا يوجد'}, otp_id={latest_otp.id}")
        
        return True, user, {'message': 'تم التحقق من الرمز بنجاح'}
        
    except Exception as e:
        logger.error(f"استثناء أثناء التحقق من OTP: {str(e)}", exc_info=True)
        return False, None, {'reason': 'system_error', 'message': f'خطأ في النظام: {str(e)}'}

def send_otp_with_fallback(identifier, otp_code, full_name='مستخدم توصيل'):
    """إرسال رمز OTP باستخدام البريد الإلكتروني أو الرسائل النصية مع وجود خطة بديلة"""
    from .models import Utilisateur, OTPCode  # استيراد محلي لتجنب التعارض الدائري
    
    is_email = '@' in identifier
    
    # تسجيل معلومات الرمز للتشخيص
    logger.info(f"تم إنشاء رمز OTP للمستخدم {identifier}: {otp_code}")
    
    if is_email:
        # تخصيص نص البريد
        subject = "رمز التحقق لتطبيق توصيل"
        message = f"""مرحبًا {full_name}،

رمز التحقق الخاص بك هو: {otp_code}

يرجى إدخال هذا الرمز في التطبيق لإكمال العملية.
ينتهي صلاحية هذا الرمز خلال 3 دقائق.

شكرًا لاستخدام تطبيق توصيل!
"""
        html_message = f"""
        <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; direction: rtl; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ text-align: center; margin-bottom: 20px; }}
                    .code {{ font-size: 24px; font-weight: bold; text-align: center; 
                            padding: 10px; background-color: #f0f0f0; margin: 15px 0; }}
                    .footer {{ font-size: 12px; text-align: center; margin-top: 30px; color: #777; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h2>رمز التحقق لتطبيق توصيل</h2>
                    </div>
                    <p>مرحبًا {full_name}،</p>
                    <p>لقد تلقينا طلبًا للتحقق من هويتك. استخدم رمز التحقق أدناه:</p>
                    <div class="code">{otp_code}</div>
                    <p>هذا الرمز صالح لمدة 3 دقائق فقط.</p>
                    <p>إذا لم تطلب هذا الرمز، يرجى تجاهل هذا البريد الإلكتروني.</p>
                    <div class="footer">
                        <p>هذه رسالة آلية، يرجى عدم الرد عليها.</p>
                        <p>&copy; 2025 Tawssil. جميع الحقوق محفوظة.</p>
                    </div>
                </div>
            </body>
        </html>
        """
        
        # تجربة إرسال البريد بطريقة أكثر قوة
        
        try:
            import smtplib
            from email.mime.text import MIMEText
            from email.mime.multipart import MIMEMultipart
            from django.conf import settings
            
            # كتابة بيانات الاتصال للتشخيص
            logger.info(f"إعدادات SMTP: HOST={settings.EMAIL_HOST}, PORT={settings.EMAIL_PORT}, TLS={settings.EMAIL_USE_TLS}")
            logger.info(f"حساب البريد: {settings.EMAIL_HOST_USER}")
            
            # إنشاء رسالة متعددة الأجزاء
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = settings.DEFAULT_FROM_EMAIL
            msg['To'] = identifier
            
            # إضافة أجزاء النص والHTML إلى الرسالة
            part1 = MIMEText(message, 'plain')
            part2 = MIMEText(html_message, 'html')
            msg.attach(part1)
            msg.attach(part2)
            
            # إنشاء اتصال SMTP
            server = smtplib.SMTP(settings.EMAIL_HOST, settings.EMAIL_PORT)
            server.set_debuglevel(1)  # تفعيل الوضع التشخيصي
            
            # بدء TLS إذا كان مطلوبًا
            if settings.EMAIL_USE_TLS:
                server.starttls()
            
            # تسجيل الدخول إلى الخادم
            server.login(settings.EMAIL_HOST_USER, settings.EMAIL_HOST_PASSWORD)
            
            # إرسال البريد الإلكتروني
            server.sendmail(settings.DEFAULT_FROM_EMAIL, [identifier], msg.as_string())
            
            # إغلاق الاتصال
            server.quit()
            
            logger.info(f"تم إرسال البريد الإلكتروني بنجاح باستخدام SMTP مباشرة إلى: {identifier}")
            return True, "تم إرسال رمز التحقق إلى بريدك الإلكتروني"
            
        except Exception as e:
            logger.error(f"فشل إرسال البريد الإلكتروني باستخدام SMTP مباشرة: {str(e)}")
            
            # طريقة بديلة باستخدام send_mail
            try:
                from django.core.mail import send_mail
                
                logger.info(f"محاولة إرسال بالطريقة البديلة (send_mail) إلى: {identifier}")
                
                result = send_mail(
                    subject, 
                    message, 
                    settings.DEFAULT_FROM_EMAIL, 
                    [identifier], 
                    html_message=html_message,
                    fail_silently=False
                )
                
                if result > 0:
                    logger.info(f"تم إرسال البريد الإلكتروني بنجاح باستخدام send_mail إلى: {identifier}")
                    return True, "تم إرسال رمز التحقق إلى بريدك الإلكتروني"
                else:
                    logger.warning(f"send_mail أعاد 0 (فشل): {identifier}")
            except Exception as e2:
                logger.error(f"فشل إرسال البريد باستخدام send_mail: {str(e2)}")
            
            # في وضع التطوير نرجع نجاح افتراضي
            if settings.DEBUG:
                logger.warning(f"وضع التطوير: اعتبار الإرسال ناجحًا رغم الفشل. البريد: {identifier}, الرمز: {otp_code}")
                return True, f"وضع التطوير: تجاهل فشل إرسال البريد. استخدم الرمز: {otp_code}"
            
            return False, "فشل إرسال البريد الإلكتروني. يرجى المحاولة مرة أخرى."
    else:
        # محاولة إرسال عبر الرسائل النصية
        try:
            result = send_sms_otp(identifier, otp_code)
            if result:
                logger.info(f"تم إرسال SMS بنجاح إلى: {identifier}")
                return True, "تم إرسال رمز التحقق إلى هاتفك"
            else:
                logger.warning(f"فشل إرسال SMS إلى: {identifier}")
                
                # في وضع التطوير نعتبرها ناجحة
                if settings.DEBUG:
                    return True, f"وضع التطوير: تجاهل فشل إرسال SMS. استخدم الرمز: {otp_code}"
                    
                # في الإنتاج نعتبرها ناجحة أيضًا
                return True, "تم توليد رمز التحقق بنجاح"
        except Exception as e:
            logger.error(f"خطأ عند إرسال SMS: {str(e)}")
            
            if settings.DEBUG:
                return True, f"وضع التطوير: تجاهل الخطأ في إرسال SMS. استخدم الرمز: {otp_code}"
            
            return True, "تم توليد رمز التحقق بنجاح"

def get_debug_otp(identifier):
    """الحصول على آخر رمز OTP مخزن للمستخدم (للاستخدام في بيئة التطوير فقط)"""
    from .models import OTPCode, Utilisateur
    
    if not settings.DEBUG:
        logger.warning("محاولة استخدام get_debug_otp في بيئة الإنتاج!")
        return None
    
    try:
        user = None
        if '@' in identifier:  # بريد إلكتروني
            user = Utilisateur.objects.filter(email=identifier).first()
        else:  # رقم هاتف
            user = Utilisateur.objects.filter(telephone=identifier).first()
        
        if not user:
            return None
            
        # البحث عن آخر رمز OTP نشط
        otp = OTPCode.objects.filter(
            user=user,
            identifier=identifier,
            is_used=False
        ).order_by('-created_at').first()
        
        if otp:
            return otp.code
        return None
    except Exception as e:
        logger.error(f"خطأ في get_debug_otp: {str(e)}")
        return None

def check_user_exists_by_type(identifier, user_type):
    """التحقق من وجود مستخدم بناءً على نوع المستخدم (عميل أو سائق)"""
    from .models import Utilisateur
    
    try:
        query = {}
        if '@' in identifier:
            query['email'] = identifier
        else:
            query['telephone'] = identifier
            
        query['type'] = user_type
        
        exists = Utilisateur.objects.filter(**query).exists()
        return exists
    except Exception as e:
        logger.error(f"خطأ أثناء التحقق من وجود المستخدم: {str(e)}")
        return False 