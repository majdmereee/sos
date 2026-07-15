# تهيئة المستودع محلياً
git init

# إضافة جميع الملفات
git add .

# تسجيل التغييرات
git commit -m "Initial commit with instant SOS setup"

# ربط المستودع المحلي بمستودع GitHub (استبدل الرابط برابط مستودعك الجديد)
git remote add origin https://github.com/YOUR_USERNAME/instant-sos-app.git

# رفع الكود
git branch -M main
git push -u origin main
