FROM rockylinux:9

# Install necessary tools
RUN dnf install -y nodejs npm git rpm-build rpmlint rpmdevtools

# Set up the action directory
WORKDIR /action

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy the rest of your action's source code
COPY . .

# Build your action (if using TypeScript)
RUN npm run package

# Run the action
ENTRYPOINT ["node", "/action/dist/index.js"]