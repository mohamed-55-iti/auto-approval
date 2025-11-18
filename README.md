# 🚀 Auto-Approval System

نظام موافقات تلقائي ذكي لـ GitHub Pull Requests

## المميزات
- ✅ موافقة تلقائية للتعديلات الآمنة
- ✅ فحص عدد الملفات والتغييرات
- ✅ كشف الملفات الحساسة
- ✅ تكامل مع GitHub Actions

## التثبيت
```bash
git clone https://github.com/mohamed-55-iti/auto-approval.git
cd auto-approval

# إنشاء .env
cat > .env << 'EOL'
GITHUB_TOKEN="your-token"
REPO_OWNER="your-username"
REPO_NAME="your-repo"
EOL

chmod 600 .env
```

## الاستخدام
```bash
source .env
./scripts/auto_approve_github.sh
```

## المعايير الافتراضية

- عدد الملفات: ≤ 10
- التغييرات: ≤ 100 سطر
- لا ملفات حساسة
- الاختبارات ناجحة

## الوثائق

- [دليل الاستخدام](docs/usage.md)
- [أمثلة](docs/examples.md)

## الترخيص

MIT License

---

⭐ Star the repo if you find it useful!
# Test
