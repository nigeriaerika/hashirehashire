# Step A: Use an official, lightweight Node.js base image.
FROM node:18-alpine

# Step B: Set the working directory inside the container.
WORKDIR /usr/src/app

# Step C: Copy the package.json file to the container.
# This is done first to leverage Docker's layer caching.
COPY package*.json ./

# Step D: Install the dependencies defined in package.json.
# This will install `node-tcp-proxy`.
RUN npm install

# Step E: Expose the internal port your proxy will listen on.
# This is for documentation and can be used by other tools.
EXPOSE 8080

# Step F: Define the command to run your application.
# This executes the "start" script from your package.json file.
CMD [ "npm", "start" ]
