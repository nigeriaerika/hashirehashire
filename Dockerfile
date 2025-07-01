# Dockerfile for Northflank Combined Service

# 1. Start with a lightweight, official Node.js image.
FROM node:18-slim

# 2. Install the node-tcp-proxy package globally.
RUN npm install -g node-tcp-proxy --no-update-notifier
RUN apt-get update -y;apt-get install htop curl wget -y

EXPOSE 8080
EXPOSE 443/tcp
EXPOSE 443/udp
EXPOSE 444/tcp
EXPOSE 444/udp

# 3. Define the command that will be run when the container starts.
#    It listens on the internal port Northflank provides via the $PORT environment variable.
CMD ["sh", "-c", "sleep 999999"]
