#!/bin/bash

# Complete HerbionYX Fabric Network Setup Script
# This script sets up the entire Hyperledger Fabric network from scratch

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HerbionYX Fabric Network Setup${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if we're in the right directory
if [ ! -f "configtx.yaml" ]; then
    echo -e "${RED}Error: Must run from fabric-network/scripts directory${NC}"
    echo -e "${YELLOW}Current directory: $(pwd)${NC}"
    exit 1
fi

# Step 1: Create directory structure
echo -e "${GREEN}Step 1: Creating directory structure...${NC}"
mkdir -p ../channel-artifacts
mkdir -p ../organizations/ordererOrganizations
mkdir -p ../organizations/peerOrganizations
mkdir -p ../organizations/fabric-ca

# Step 2: Clean up any existing network
echo -e "${GREEN}Step 2: Cleaning up existing network...${NC}"
cd ..
docker-compose down --volumes --remove-orphans 2>/dev/null || true
docker system prune -f
cd scripts

# Step 3: Generate certificates
echo -e "${GREEN}Step 3: Generating certificates...${NC}"
./generate-certs.sh

# Step 4: Generate genesis block
echo -e "${GREEN}Step 4: Generating genesis block...${NC}"
export FABRIC_CFG_PATH=${PWD}
configtxgen -profile HerbionYXSystemChannel -channelID system-channel -outputBlock ../channel-artifacts/genesis.block

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to generate genesis block${NC}"
    exit 1
fi

# Step 5: Start the network
echo -e "${GREEN}Step 5: Starting Fabric network...${NC}"
cd ..
docker-compose up -d

# Wait for containers to start
echo -e "${YELLOW}Waiting for containers to start...${NC}"
sleep 30

# Check container status
echo -e "${GREEN}Container status:${NC}"
docker-compose ps

cd scripts

# Step 6: Create channel
echo -e "${GREEN}Step 6: Creating channel...${NC}"
./network.sh createChannel

# Step 7: Deploy chaincode
echo -e "${GREEN}Step 7: Deploying chaincode...${NC}"
./network.sh deployCC

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Network setup completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}You can now start the backend server:${NC}"
echo -e "${BLUE}cd ../../server && npm run dev${NC}"