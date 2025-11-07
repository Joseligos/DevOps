#!/bin/bash
# K3d Setup Script - Automatiza todo el setup de Kubernetes local

set -e

echo "🚀 K3d Setup Script"
echo "===================="
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_step "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    print_error "Docker not found. Please install Docker first."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_warn "kubectl not found. It will be installed with K3d."
fi

echo ""

# Menu
echo "What do you want to do?"
echo "1) Install K3d"
echo "2) Create K3d cluster"
echo "3) Create namespace and secrets"
echo "4) Deploy app to K3d"
echo "5) Show access info"
echo "6) Show logs"
echo "7) Destroy cluster"
echo "0) Exit"
echo ""
read -p "Choose option: " option

case $option in
    1)
        print_step "Installing K3d..."
        if command -v k3d &> /dev/null; then
            echo "K3d already installed: $(k3d version)"
        else
            curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
            print_step "K3d installed successfully"
        fi
        ;;
    2)
        print_step "Creating K3d cluster 'dev-cluster'..."
        k3d cluster create dev-cluster \
          --servers 1 \
          --agents 2 \
          --port 8080:80@loadbalancer \
          --port 8443:443@loadbalancer \
          --volume /tmp/k3dvol:/tmp/k3dvol@all \
          --wait
        print_step "Cluster created successfully"
        sleep 2
        kubectl get nodes
        ;;
    3)
        print_step "Creating namespace..."
        kubectl create namespace devops-app || echo "Namespace already exists"
        
        print_step "Creating database secret..."
        echo "Enter your DATABASE_URL from terraform/terraform.tfvars:"
        read -p "DATABASE_URL: " db_url
        
        kubectl create secret generic db-secret \
          --from-literal=database_url="$db_url" \
          -n devops-app --dry-run=client -o yaml | kubectl apply -f -
        
        print_step "Secret created"
        kubectl get secrets -n devops-app
        ;;
    4)
        print_step "Deploying app to K3d..."
        
        if ! kubectl get namespace devops-app &> /dev/null; then
            print_error "Namespace doesn't exist. Run option 3 first."
            exit 1
        fi
        
        print_step "Applying backend manifests..."
        kubectl apply -f kubernetes/backend/deployment.yaml
        kubectl apply -f kubernetes/backend/service.yaml
        
        print_step "Applying frontend manifests..."
        kubectl apply -f kubernetes/frontend/deployment.yaml
        kubectl apply -f kubernetes/frontend/service.yaml
        
        print_step "Waiting for pods to be ready..."
        sleep 5
        kubectl get pods -n devops-app
        
        print_step "Waiting for services to get external IPs..."
        sleep 5
        kubectl get svc -n devops-app
        
        echo ""
        echo "✅ App deployed!"
        echo ""
        echo "Access your app:"
        echo "  Frontend: http://localhost:8080"
        echo "  Backend:  http://localhost:80"
        ;;
    5)
        print_step "K3d Cluster Info"
        echo ""
        echo "Cluster status:"
        k3d cluster list
        echo ""
        echo "Services:"
        kubectl get svc -n devops-app
        echo ""
        echo "Access URLs:"
        echo "  Frontend: http://localhost:8080"
        echo "  Backend:  http://localhost:80 (or http://localhost)"
        echo ""
        echo "Test commands:"
        echo "  curl http://localhost/healthz"
        echo "  curl http://localhost/users"
        ;;
    6)
        print_step "Showing logs..."
        echo ""
        read -p "Show logs for (backend/frontend/all)? " service
        
        case $service in
            backend)
                kubectl logs -f deployment/backend -n devops-app
                ;;
            frontend)
                kubectl logs -f deployment/frontend -n devops-app
                ;;
            all)
                kubectl logs -f -l app=backend -n devops-app &
                kubectl logs -f -l app=frontend -n devops-app
                ;;
            *)
                print_error "Invalid choice"
                ;;
        esac
        ;;
    7)
        print_warn "This will delete the entire cluster!"
        read -p "Are you sure? (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            print_step "Deleting cluster..."
            k3d cluster delete dev-cluster
            print_step "Cluster deleted"
        else
            echo "Cancelled"
        fi
        ;;
    0)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        print_error "Invalid option"
        exit 1
        ;;
esac
