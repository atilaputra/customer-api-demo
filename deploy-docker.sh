#!/bin/bash
# Smart deployment script for Docker to Azure
# Configuration: app name from parameter, resource group "se-demos-rg", location "southeastasia", ACR "sedemosacr123"
# Steps:
# 1. Check and create Resource Group if not exists
# 2. Check and create Azure Container Registry if not exists  
# 3. Check and create App Service Plan (Linux, B1 SKU) if not exists
# 4. Build Docker image
# 5. Tag and push image to ACR
# 6. Check if Web App exists - if yes update container, if no create new Web App
# 7. Commit and push to GitHub
# Include progress indicators, error handling, and final summary with live URL

set -e
APP_NAME=$1
RESOURCE_GROUP="se-demos-rg"
LOCATION="southeastasia"
ACR_NAME="sedemosacr123"
APP_SERVICE_PLAN="se-demos-asp"
IMAGE_NAME="$APP_NAME-image"
IMAGE_TAG="v1"
if [ -z "$APP_NAME" ]; then
  echo "Usage: $0 <app-name>"
  exit 1
fi
echo "Starting deployment for app: $APP_NAME"
# Step 1: Check and create Resource Group
if ! az group show --name $RESOURCE_GROUP &> /dev/null; then
  echo "Creating Resource Group: $RESOURCE_GROUP"
  az group create --name $RESOURCE_GROUP --location $LOCATION
else
  echo "Resource Group $RESOURCE_GROUP already exists"
fi
# Step 2: Check and create Azure Container Registry
if ! az acr show --name $ACR_NAME &> /dev/null; then
  echo "Creating Azure Container Registry: $ACR_NAME"
  az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic
else
  echo "Azure Container Registry $ACR_NAME already exists"
fi
# Step 3: Check and create App Service Plan
if ! az appservice plan show --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "Creating App Service Plan: $APP_SERVICE_PLAN"
  az appservice plan create --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP --is-linux --sku B1
else    
  echo "App Service Plan $APP_SERVICE_PLAN already exists"
fi
# Step 4: Build Docker image
echo "Building Docker image: $IMAGE_NAME:$IMAGE_TAG"
docker build -t $IMAGE_NAME:$IMAGE_TAG .
# Step 5: Tag and push image to ACR
echo "Tagging and pushing image to ACR: $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG"
az acr login --name $ACR_NAME
docker tag $IMAGE_NAME:$IMAGE_TAG $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG
docker push $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG
# Step 6: Check if Web App exists
if az webapp show --name $APP_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "Updating existing Web App: $APP_NAME"
  az webapp config container set --name $APP_NAME --resource-group $RESOURCE_GROUP --docker-custom-image-name $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG --docker-registry-server-url https://$ACR_NAME.azurecr.io
else
  echo "Creating new Web App: $APP_NAME"
  az webapp create --name $APP_NAME --resource-group $RESOURCE_GROUP --plan $APP_SERVICE_PLAN --deployment-container-image-name $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG
fi
# Step 7: Commit and push to GitHub
echo "Committing and pushing changes to GitHub"
git add .
git commit -m "Deployed $APP_NAME to Azure"
git push origin main
# Final summary
APP_URL="https://$APP_NAME.azurewebsites.net"
echo "Deployment completed successfully!"
echo "Your application is live at: $APP_URL"    

