from django.db import migrations


class Migration(migrations.Migration):
    dependencies = [
        ('utilisateurs', '0005_utilisateur_date_joined_utilisateur_last_modified'),
    ]

    operations = [
        migrations.RunSQL(
            sql="ALTER TABLE utilisateurs_utilisateur ADD COLUMN IF NOT EXISTS last_modified TIMESTAMP WITH TIME ZONE NULL",
            reverse_sql="ALTER TABLE utilisateurs_utilisateur DROP COLUMN IF EXISTS last_modified",
        ),
    ] 