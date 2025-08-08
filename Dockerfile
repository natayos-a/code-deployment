# --- Stage 1: Build the Frontend application ---
# ใช้ Node.js 20 เป็น base image เพื่อติดตั้ง dependencies และ build
FROM node:20.19.4-alpine as builder

# ตั้งค่า working directory ภายใน container
WORKDIR /app

# คัดลอก package.json และ package-lock.json ก่อนเพื่อใช้ Docker cache
# (ถ้า frontend เป็น React จะเป็น package.json และ folder src)
COPY package*.json ./

# ติดตั้ง dependencies ของ Frontend
RUN npm install

# คัดลอก source code ทั้งหมดของ Frontend
COPY . .

# สั่ง build Frontend application
# หากเป็น React จะใช้ npm run build
# หากเป็น Angular จะใช้ ng build --prod
RUN npm run build


# --- Stage 2: Serve the built Frontend with Nginx ---
# ใช้ Nginx Alpine เป็น base image ซึ่งมีขนาดเล็กและเหมาะสำหรับ production
FROM nginx:alpine

# ลบไฟล์ default ของ Nginx ออกก่อนเพื่อไม่ให้เกิดความสับสน
RUN rm -rf /etc/nginx/conf.d/* /usr/share/nginx/html/*

# คัดลอกไฟล์ที่ build แล้วจาก Stage 'builder' ไปยัง Nginx's web root
# หากเป็น React ไฟล์จะอยู่ใน /app/build
# หากเป็น Angular ไฟล์จะอยู่ใน /app/dist/<ชื่อโปรเจกต์>
COPY --from=builder /app/build /usr/share/nginx/html

# คัดลอก Nginx configuration สำหรับ Single Page Application (SPA)
# หากคุณใช้ React Router หรือ Angular Router จะต้องมีไฟล์นี้
COPY nginx.conf /etc/nginx/nginx.conf

# เปิด Port 80 ซึ่งเป็น Port มาตรฐานของ HTTP
EXPOSE 80

# สั่งให้ Nginx ทำงาน
CMD ["nginx", "-g", "daemon off;"]