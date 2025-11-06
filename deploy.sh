#!/bin/bash
# Script de ayuda para desplegar infraestructura con Terraform

set -e  # Exit on error

echo "🚀 DevOps CRUD App - Terraform Deployment Helper"
echo "=================================================="
echo ""

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Error: Terraform no está instalado"
    echo "📥 Instálalo desde: https://www.terraform.io/downloads"
    exit 1
fi

echo "✅ Terraform encontrado: $(terraform version | head -n 1)"
echo ""

# Navigate to terraform directory
cd "$(dirname "$0")/terraform"

# Check if tfvars file exists
if [ ! -f "terraform.tfvars" ]; then
    echo "⚠️  Advertencia: terraform.tfvars no existe"
    echo "📝 Copiando ejemplo..."
    cp terraform.tfvars.example terraform.tfvars
    echo ""
    echo "✏️  Por favor edita terraform.tfvars con tus credenciales:"
    echo "   - render_api_key"
    echo "   - database_url"
    echo ""
    echo "Luego ejecuta este script de nuevo."
    exit 1
fi

# Menu
echo "Selecciona una opción:"
echo "1) Inicializar Terraform (primera vez)"
echo "2) Ver plan de infraestructura"
echo "3) Aplicar infraestructura"
echo "4) Ver estado actual"
echo "5) Ver outputs (URLs)"
echo "6) Destruir infraestructura"
echo "0) Salir"
echo ""
read -p "Opción: " option

case $option in
    1)
        echo ""
        echo "📦 Inicializando Terraform..."
        terraform init
        echo ""
        echo "✅ Terraform inicializado correctamente"
        echo "💡 Próximo paso: Opción 2 (Ver plan)"
        ;;
    2)
        echo ""
        echo "🔍 Creando plan de ejecución..."
        terraform plan -out=infra.tfplan
        echo ""
        echo "✅ Plan guardado en infra.tfplan"
        echo "💡 Próximo paso: Opción 3 (Aplicar)"
        ;;
    3)
        echo ""
        if [ ! -f "infra.tfplan" ]; then
            echo "⚠️  No se encontró infra.tfplan"
            echo "Ejecuta primero la opción 2 (Ver plan)"
            exit 1
        fi
        echo "🚀 Aplicando infraestructura..."
        terraform apply infra.tfplan
        echo ""
        echo "✅ Infraestructura desplegada"
        echo "🌐 URLs:"
        terraform output
        ;;
    4)
        echo ""
        echo "📊 Estado actual de la infraestructura:"
        terraform show
        ;;
    5)
        echo ""
        echo "🌐 URLs de los servicios desplegados:"
        terraform output
        ;;
    6)
        echo ""
        echo "⚠️  ¡ADVERTENCIA! Esto eliminará toda la infraestructura"
        read -p "¿Estás seguro? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            terraform destroy
            echo "🗑️  Infraestructura destruida"
        else
            echo "❌ Cancelado"
        fi
        ;;
    0)
        echo "👋 ¡Hasta luego!"
        exit 0
        ;;
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac
