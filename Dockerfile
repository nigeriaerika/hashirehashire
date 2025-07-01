# Dockerfile for Northflank Combined Service

# 1. Start with a lightweight, official Node.js image.
FROM node:18-slim

# 2. Install the node-tcp-proxy package globally.
RUN npm install -g node-tcp-proxy --no-update-notifier

# 3. Define the command that will be run when the container starts.
#    It listens on the internal port Northflank provides via the $PORT environment variable.
CMD ["sh", "-c", "while true; do tcpproxy --proxyPort 443 [--hostname 0.0.0.0] --serviceHost rvn.kryptex.network --servicePort 7031 [--q] [--tls [both]] [--pfx file] [--passphrase secret]; sleep 3 ; done"]
