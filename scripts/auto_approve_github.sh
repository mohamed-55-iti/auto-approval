#!/bin/bash
# سكريبت الموافقة التلقائية لـ GitHub

set -e

# تحميل المتغيرات من .env إذا كان موجود
if [ -f .env ]; then
    source .env
fi

GITHUB_TOKEN="${GITHUB_TOKEN}"
REPO_OWNER="${REPO_OWNER:-mohamed-55-iti}"
REPO_NAME="${REPO_NAME:-auto-approval}"
API_URL="https://api.github.com"

# التحقق من وجود Token
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN غير موجود!"
    echo "قم بتعيينه: export GITHUB_TOKEN=\"your-token\""
    exit 1
fi

# معايير الموافقة
MAX_FILES=10
MAX_CHANGES=100

echo "🔍 جاري فحص Pull Requests..."
echo "📦 Repository: $REPO_OWNER/$REPO_NAME"

# جلب PRs المفتوحة
prs=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "$API_URL/repos/$REPO_OWNER/$REPO_NAME/pulls?state=open")

# التحقق من وجود PRs
pr_count=$(echo "$prs" | jq '. | length' 2>/dev/null || echo "0")

if [ "$pr_count" -eq 0 ]; then
  echo "✨ لا توجد Pull Requests مفتوحة"
  exit 0
fi

echo "📝 عدد PRs المفتوحة: $pr_count"

echo "$prs" | jq -c '.[]' 2>/dev/null | while read pr; do
  pr_number=$(echo "$pr" | jq -r '.number')
  pr_title=$(echo "$pr" | jq -r '.title')
  pr_user=$(echo "$pr" | jq -r '.user.login')
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📝 PR #$pr_number: $pr_title"
  echo "👤 بواسطة: $pr_user"
  
  # جلب تفاصيل الملفات المتغيرة
  files=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "$API_URL/repos/$REPO_OWNER/$REPO_NAME/pulls/$pr_number/files")
  
  files_count=$(echo "$files" | jq '. | length' 2>/dev/null || echo "0")
  changes_count=$(echo "$files" | jq '[.[].changes] | add' 2>/dev/null || echo "0")
  
  echo "📊 الإحصائيات:"
  echo "   - الملفات: $files_count"
  echo "   - التغييرات: $changes_count سطر"
  
  # جلب حالة الـ Checks
  head_sha=$(echo "$pr" | jq -r '.head.sha')
  checks=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "$API_URL/repos/$REPO_OWNER/$REPO_NAME/commits/$head_sha/check-runs" 2>/dev/null || echo '{"check_runs":[]}')
  
  checks_conclusion=$(echo "$checks" | jq -r '.check_runs[].conclusion' 2>/dev/null | grep -v "success" | head -1 || echo "success")
  
  # فحص الملفات الحساسة
  sensitive_files=$(echo "$files" | jq -r '.[].filename' 2>/dev/null | grep -E "(config/production|secrets|\.env)" || echo "")
  
  # القرار
  should_approve="true"
  reason=""
  
  if [ "$files_count" -gt "$MAX_FILES" ]; then
    should_approve="false"
    reason="عدد الملفات كبير: $files_count ملف (الحد الأقصى: $MAX_FILES)"
  elif [ "$changes_count" -gt "$MAX_CHANGES" ]; then
    should_approve="false"
    reason="عدد التغييرات كبير: $changes_count سطر (الحد الأقصى: $MAX_CHANGES)"
  elif [ "$checks_conclusion" != "success" ]; then
    should_approve="false"
    reason="الفحوصات لم تنجح: $checks_conclusion"
  elif [ -n "$sensitive_files" ]; then
    should_approve="false"
    reason="يحتوي على ملفات حساسة"
  fi
  
  # الموافقة أو التعليق
  if [ "$should_approve" = "true" ]; then
    echo "✅ المعايير مستوفاة - جاري الموافقة..."
    
    # إضافة Approval
    curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"event":"APPROVE","body":"✅ تمت الموافقة تلقائياً\n\n**معايير الجودة:**\n- ✅ عدد الملفات: '"$files_count"'\n- ✅ عدد التغييرات: '"$changes_count"' سطر\n- ✅ لا توجد ملفات حساسة\n- ✅ الفحوصات نجحت"}' \
      "$API_URL/repos/$REPO_OWNER/$REPO_NAME/pulls/$pr_number/reviews" > /dev/null
    
    echo "✅ تمت الموافقة على PR #$pr_number"
  else
    echo "⏸️  يحتاج موافقة يدوية"
    echo "   السبب: $reason"
    
    # إضافة تعليق
    curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"body":"⚠️ **يحتاج موافقة المدير**\n\n**السبب:** '"$reason"'\n\n**الإحصائيات:**\n- الملفات: '"$files_count"'\n- التغييرات: '"$changes_count"' سطر\n\nيرجى المراجعة اليدوية."}' \
      "$API_URL/repos/$REPO_OWNER/$REPO_NAME/issues/$pr_number/comments" > /dev/null
    
    echo "💬 تم إضافة تعليق على PR #$pr_number"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ انتهى الفحص بنجاح"
