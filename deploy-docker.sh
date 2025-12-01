#!/bin/bash
set -e

echo "🐳 Docker Deployment (Create or Update)"
echo "========================================"
echo ""

# ============================================
# CONFIGURATION
# ============================================
APP_NAME=${1:-customer-demo-api}
RESOURCE_GROUP="se-demos-rg"
LOCATION="southeastasia"
ACR_NAME="sedemosacr123"
APP_SERVICE_PLAN="demo-docker-plan"
IMAGE_NAME="$APP_NAME:latest"

echo "📋 Configuration:"
echo "   App Name: $APP_NAME"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Location: $LOCATION"
echo "   Container Registry: $ACR_NAME"
echo ""

# ============================================
# STEP 1: RESOURCE GROUP
# ============================================
echo "📦 [1/6] Checking Resource Group..."
if az group exists --name $RESOURCE_GROUP | grep -q "true"; then
  echo "   ℹ️  Resource Group already exists - skipping"
else
  echo "   Creating Resource Group..."
  az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --output none
  echo "   ✅ Resource Group created"
fi
echo ""

# ============================================
# STEP 2: CONTAINER REGISTRY
# ============================================
echo "🗄️  [2/6] Checking Container Registry..."
if az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
  echo "   ℹ️  Container Registry already exists - skipping"
else
  echo "   Creating Container Registry..."
  az acr create \
    --name $ACR_NAME \
    --resource-group $RESOURCE_GROUP \
    --sku Basic \
    --admin-enabled true \
    --output none
  echo "   ✅ Container Registry created"
fi
echo ""

# ============================================
# STEP 3: APP SERVICE PLAN
# ============================================
echo "📋 [3/6] Checking App Service Plan..."
if az appservice plan show --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP &>/dev/null; then
  echo "   ℹ️  App Service Plan already exists - skipping"
else
  echo "   Creating App Service Plan..."
  az appservice plan create \
    --name $APP_SERVICE_PLAN \
    --resource-group $RESOURCE_GROUP \
    --is-linux \
    --sku B1 \
    --location $LOCATION \
    --output none
  echo "   ✅ App Service Plan created"
fi
echo ""

# ============================================
# STEP 4: BUILD IN AZURE (No local Docker!)
# ============================================
echo "🏗️  [4/6] Building Docker image in Azure..."
echo "   This may take 2-3 minutes..."
az acr build \
  --registry $ACR_NAME \
  --image $IMAGE_NAME \
  --file Dockerfile \
  .
echo "   ✅ Image built and pushed to ACR"
echo ""

# ============================================
# STEP 5: WEB APP
# ============================================
echo "🌐 [5/6] Checking Web App..."
if az webapp show --name $APP_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
  echo "   ℹ️  Web App exists - updating container..."
  
  # Update container image
  az webapp config container set \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --docker-custom-image-name $ACR_NAME.azurecr.io/$IMAGE_NAME \
    --output none
  
  # Ensure WEBSITES_PORT is set
  az webapp config appsettings set \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --settings WEBSITES_PORT=3000 \
    --output none
  
  # Restart to pull new image
  az webapp restart \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --output none
  
  echo "   ✅ Web App updated with new container"
else
  echo "   Creating new Web App..."
  
  # Get ACR credentials
  ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
  ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)
  
  # Create Web App
  az webapp create \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --plan $APP_SERVICE_PLAN \
    --deployment-container-image-name $ACR_NAME.azurecr.io/$IMAGE_NAME \
    --docker-registry-server-url https://$ACR_NAME.azurecr.io \
    --docker-registry-server-user $ACR_USERNAME \
    --docker-registry-server-password $ACR_PASSWORD \
    --output none
  
  # Configure app settings
  az webapp config appsettings set \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --settings WEBSITES_PORT=3000 \
    --output none
  
  echo "   ✅ Web App created"
fi
echo ""

# ============================================
# STEP 6: PUSH TO GITHUB
# ============================================
echo "📤 [6/6] Pushing to GitHub..."
git add .
COMMIT_MSG="Deploy $APP_NAME - $(date +%Y-%m-%d_%H:%M)"
git commit -m "$COMMIT_MSG" 2>/dev/null || echo "   ℹ️  No changes to commit"
git push origin main 2>/dev/null || echo "   ℹ️  Already up to date"
echo "   ✅ Code synced to GitHub"
echo ""

# ============================================
# DEPLOYMENT COMPLETE
# ============================================
echo "========================================"
echo "✅ DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""
echo "🐳 Docker Image:"
echo "   $ACR_NAME.azurecr.io/$IMAGE_NAME"
echo ""
echo "🌐 Live Application:"
echo "   https://$APP_NAME.azurewebsites.net"
echo ""
echo "💡 Next steps:"
echo "   - Test API: https://$APP_NAME.azurewebsites.net/api/customers"
echo "   - View logs: az webapp log tail -n $APP_NAME -g $RESOURCE_GROUP"
echo "   - To redeploy: bash deploy-docker.sh $APP_NAME"
echo ""
echo "========================================"