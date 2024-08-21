FROM rockylinux:9

# Install Node.js and npm
RUN dnf install -y nodejs npm

# Install necessary RPM build tools and other dependencies
RUN dnf install -y dnf-plugins-core && \
    dnf config-manager --set-enabled crb && \
    dnf config-manager --set-enabled devel && \
    dnf install -y \
    git \
    rpm-build \
    epel-release \
    rpmlint \
    rpmdevtools \
    gcc \
    make \
    && dnf clean all

# Create a directory for the action code
RUN mkdir -p /usr/src/app

# Set the working directory inside the container
WORKDIR /usr/src/app

COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of your action's source code
COPY . .

RUN npm run build

ENTRYPOINT ["node", "/usr/src/app/dist/main.js"]
