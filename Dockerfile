# Step A: Use an official, lightweight Node.js base image.
FROM node:18-alpine

# Step B: Set the working directory inside the container.
WORKDIR /usr/src/app

# Step C: Copy the package.json file to the container.
COPY package*.json ./

# Step D: Install the wstunnel dependency.
RUN npm install

# Step E: Expose the internal port the tunnel will listen on.
EXPOSE 8080

# Step F: Define the command to run the tunnel server.
CMD [ "npm", "start" ]
