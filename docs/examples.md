# 📚 أمثلة

## مثال 1: تشغيل بسيط
```bash
export GITHUB_TOKEN="your-token"
./scripts/auto_approve_github.sh
```

## مثال 2: جدولة
```bash
# كل 30 دقيقة
*/30 * * * * cd /root/auto-approval && source .env && ./scripts/auto_approve_github.sh
```
