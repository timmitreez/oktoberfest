#!/bin/bash

# Script to clean up all Docker data (containers, images, volumes, networks)
# Use with caution, as it will remove ALL Docker data.

echo "Starting Docker cleanup script..."

# Stop all running containers
echo "Stopping all running containers..."
docker stop $(docker ps -q)

# Remove all containers
echo "Removing all containers..."
docker rm $(docker ps -aq)

# Remove all images
echo "Removing all Docker images..."
docker rmi $(docker images -q) --force

# Remove all volumes
echo "Removing all Docker volumes..."
docker volume rm $(docker volume ls -q)

# Remove all networks (except default ones)
echo "Removing all Docker networks..."
docker network rm $(docker network ls -q)

# Prune all dangling resources (caches, etc.)
echo "Pruning unused Docker resources..."
docker system prune --all --volumes --force

echo "Docker cleanup completed successfully!"

# Show space usage after cleanup
echo "Docker disk usage after cleanup:"
docker system df
