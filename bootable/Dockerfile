FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages for building the bootable system
RUN apt-get update && apt-get install -y \
    debootstrap \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-utils \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    dosfstools \
    curl \
    wget \
    rsync \
    git \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18.x (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Set working directory
WORKDIR /build

# Copy the entire project structure
COPY frontend ./frontend
COPY backend ./backend
COPY electron ./electron
COPY package.json ./package.json
COPY build.sh ./bootable/build.sh
COPY config ./bootable/config
COPY app ./bootable/app
COPY scripts ./bootable/scripts

# Make scripts executable
RUN chmod +x bootable/build.sh bootable/scripts/*.sh

# Default command
WORKDIR /build/bootable
CMD ["./build.sh"] 