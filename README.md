# Infraestructura como Código (IaC) con Terraform y Ansible

Este repositorio automatiza el aprovisionamiento y la configuración de una infraestructura en la nube utilizando Terraform, Ansible y AWS Lambda. La configuración incluye gestión de pares de llaves, aprovisionamiento de infraestructura, despliegue de aplicaciones y gestión de configuración.

## Características

- **Generación Automatizada de Claves SSH** para acceso seguro.
- **Terraform** para el aprovisionamiento de infraestructura (incluyendo un nodo de control Ansible y un balanceador de carga).
- **AWS Lambda** empaquetado para funciones sin servidor.
- **Ansible** para la gestión de configuración y el despliegue de aplicaciones.
- **Automatización integral** con un único script de shell.

## Prerrequisitos

- [Terraform](https://www.terraform.io/downloads)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [AWS CLI](https://aws.amazon.com/cli/)
- Shell Bash (Linux/macOS o WSL en Windows)
- Cliente SSH

## Estructura del Proyecto

```

├── lambda_python/                   # Código Python para funciones AWS Lambda
│   ├── read_lambda.py
│   └── seed_lambda.py
├── terraform/                       # Archivos de configuración de Terraform
│   └──  html/                       # Archivos de la aplicación web
└── build_infraestructure.sh         # Script principal de automatización
```

## Uso

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/fcuya13/devops-exposicion-1.git
   cd devops-exposicion-1
   ```

2. **Ejecutar el script de automatización:**
   ```bash
   ./build_infraestructure.sh
   ```

   Este script realizará:
   - Generación de claves SSH y configuración de permisos.
   - Empaquetado de funciones Lambda.
   - Inicialización y aplicación de la configuración de Terraform.
   - Espera a que el nodo de control Ansible esté listo.
   - Copia de archivos necesarios al nodo de control.
   - Ejecución del playbook de Ansible para configuración y despliegue.
   - Imprime la URL del Balanceador de Carga para acceder a la aplicación desplegada.

3. **Acceder a la aplicación:**
   - Tras la finalización del script, abra la URL en su navegador.
     ```
     Load Balancer URL: http://<url-del-balanceador>/index.php
     ```
## Limpieza

Para destruir la infraestructura, ejecute:
```bash
cd terraform
terraform destroy
```


## Notas

- El script asume que tiene los permisos y credenciales necesarios para aprovisionar recursos en su proveedor de nube.
- Las claves SSH se generan y gestionan localmente en el directorio `keys/`, mientras que la configuración de Ansible se genera localmente en el directorio `terraform/ansible/ `
- La IP pública del nodo de control Ansible y la URL del balanceador de carga se obtienen dinámicamente de las salidas de Terraform.

