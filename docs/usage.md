# 📖 دليل الاستخدام

## التشغيل اليدوي
```bash
source .env
./scripts/auto_approve_github.sh
```

## التشغيل مع Cron
```bash
crontab -e

# كل ساعة
0 * * * * cd /root/auto-approval && source .env && ./scripts/auto_approve_github.sh
```

## التعديل على المعايير

عدّل `config/approval_rules.yaml` لتغيير القواعد.
