# Start Nginx in the background
nginx -g 'daemon off;' &

# Start Node.js Backend
# ตรวจสอบให้แน่ใจว่า path ไปยัง backend.js ถูกต้อง
node /code-deployment/backend/backend.js