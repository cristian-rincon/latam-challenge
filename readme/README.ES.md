# latam-challenge

[![CI](https://github.com/cristian-rincon/latam-challenge/actions/workflows/ci.yaml/badge.svg)](https://github.com/cristian-rincon/latam-challenge/actions/workflows/ci.yaml)
[![CD](https://github.com/cristian-rincon/latam-challenge/actions/workflows/cd.yaml/badge.svg)](https://github.com/cristian-rincon/latam-challenge/actions/workflows/cd.yaml)

## Contents

- [latam-challenge](#latam-challenge)
  - [Contents](#contents)
  - [Objetivo](#objetivo)
  - [Solución](#solución)
  - [Setup](#setup)
    - [Pre-requisitos](#pre-requisitos)
      - [Opcional](#opcional)
    - [Apis que se deben habilitar](#apis-que-se-deben-habilitar)
  - [1. Infraestructura](#1-infraestructura)
    - [1.1 Inicialización](#11-inicialización)
    - [1.2 Plan](#12-plan)
    - [1.3 Apply](#13-apply)
  - [2. Aplicaciones y Flujo de CI/CD](#2-aplicaciones-y-flujo-de-cicd)
    - [2.1 Ingesta de Datos (HTTP API)](#21-ingesta-de-datos-http-api)
    - [2.2 Consulta de datos](#22-consulta-de-datos)
  - [3. CI/CD](#3-cicd)
    - [3.1 Estrategia de ramas](#31-estrategia-de-ramas)
    - [3.2 Crear una cuenta de servicio privilegiada para Terraform](#32-crear-una-cuenta-de-servicio-privilegiada-para-terraform)
    - [3.3 Pre-requisitos de GitHub Actions](#33-pre-requisitos-de-github-actions)
      - [3.3.1 Entornos de GitHub](#331-entornos-de-github)

## Objetivo

Desarrollar un sistema en la nube para ingestar, almacenar y exponer datos mediante el uso de IaC y despliegue con flujos CI/CD. Hacer pruebas de calidad, monitoreo y alertas para asegurar y monitorear la salud del sistema.

## Solución

La solución planteada consiste en un sistema que ingesta, almacena y expone datos utilizando recursos de Google Cloud optimizados para un flujo de datos que utilice un esquema pub/sub.

Para esta solución se emplearán los siguientes componentes:

- Google Cloud Platform
  - IAM: Roles y Cuentas de Servicio
  - Pub/Sub: Tópicos y Suscripciones
  - Cloud Run Functions: Ingesta y Consulta de datos
  - Bigquery: Dataset y Tablas para almacenamiento de datos (enfocado en analítica de datos)
- GitHub:
  - Repositorio: Para almacenamiento del código fuente
  - Actions: Para la orquestación de los flujos de CI/CD
  - Entornos: Para manejo de despliegues, secretos, y variables hacia distintos entornos.
  - Seguridad:
    - Avisos: Ver o divulgar avisos de seguridad para este repositorio
    - Alertas de escaneo de secretos: Recibir una notificación cuando se envíe un secreto a este repositorio

## Setup

### Pre-requisitos

- [Gcloud CLI](https://cloud.google.com/sdk/docs/install?hl=es-419)
- [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Python 3.9+](https://www.python.org/downloads/)

#### Opcional

- [Terraform Docs](https://terraform-docs.io/)
- [NodeJS](https://nodejs.org/en/download/package-manager) (Pre-requisite for auto-changelog)
- [Auto-Changelog](https://www.npmjs.com/package/auto-changelog)

### Apis que se deben habilitar

En caso de que desee realizar pruebas desde local, usted (o una cuenta de servicio) debe tener suficientes permisos para habilitar las siguientes API:

- Billing API (Solo en caso de que deba [crear un proyecto desde cero](https://developers.google.com/workspace/guides/create-project#google-cloud-console))
- Cloud Functions API
- Pub/Sub API
- Bigquery API
- Identity and Access Management (IAM) API
- Cloud Resource Manager API

## 1. Infraestructura

### 1.1 Inicialización

> **Importante:** probado con Terraform v1.8.1

```bash
cd infra
terraform init
```

Crea un nuevo archivo llamado terraform.tfvars con la siguiente información:

```md
project_id=<YOUR_GCP_PROJECT_ID>
region=<YOUR_GCP_REGION>
environment=<ENVIRONMENT_NAME>
```

### 1.2 Plan

```bash
terraform plan -var-file=terraform.tfvars
```

### 1.3 Apply

```bash
terraform apply -var-file=terraform.tfvars
```

## 2. Aplicaciones y Flujo de CI/CD

Para este desafío, se desarrolló un caso de uso enfocado en la ingesta de datos de ventas de productos.

El esquema de la tabla que se va a llenar es el siguiente:

```tf
  schema = <<EOF
  [
    {
      "name": "product_id",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "product_name",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "category",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "unit_price",
      "type": "FLOAT",
      "mode": "REQUIRED"
    },
    {
      "name": "supplier",
      "type": "STRING",
      "mode": "REQUIRED"
    }
  ]
    EOF
```

### 2.1 Ingesta de Datos (HTTP API)

El proceso de ingesta de datos lo gestiona una [función de la nube](https://cloud.google.com/functions?hl=en) (HTTP), que activa un tema de Pub/Sub. Luego, el servicio suscrito transmite los datos entrantes a una tabla de BigQuery para su almacenamiento y análisis.

> Terraform implementa la [función de la nube](https://cloud.google.com/functions?hl=en) en un proceso de CD orquestado por flujos de trabajo de GitHub Actions. Detalles [aquí](#3-cicd)

Código Fuente: /product_sales/ingestion

Ejemplo de consulta:

```bash
curl -m 310 -X POST https://<fn_ingest_data_url> \
-H "Authorization: bearer $(gcloud auth print-identity-token)" -H "Content-Type: application/json" \
-d '{
    "product_id": "45678",
    "product_name": "Laptop 2",
    "category": "Electronics",
    "unit_price": 999.99,
    "supplier": "TechSupplier Inc."
}'
```

### 2.2 Consulta de datos

El proceso de consulta de datos es posible gracias a una funcion de la nube (HTTP) que consulta el top 10 de datos guardados en el datawarehouse de Bigquery.

> Terraform implementa la función de la nube en un proceso de CD orquestado por flujos de trabajo de GitHub Actions. Detalles [aquí](#3-cicd)

Código Fuente: /product_sales/fetch

Ejemplo de consulta:

```bash
curl -m 310 -X POST https://<fn_fetch_data_url> \
-H "Authorization: bearer $(gcloud auth print-identity-token)" -H "Content-Type: application/json" \
-d '{}'
```

## 3. CI/CD

El proceso de CI/CD está organizado por [GitHub Actions](https://docs.github.com/en/actions). Puedes encontrar los flujos de trabajo actuales en la carpeta `.github/workflows/`.

### 3.1 Estrategia de ramas

El repositorio se ha organizado para utilizar [Gitflow](https://www.atlassian.com/es/git/tutorials/comparing-workflows/gitflow-workflow#:~:text=%C2%BFQu%C3%A9%20es%20Gitflow%3F,vez%20y%20quien%20lo%20populariz%C3%B3.). Por lo anterior, existe una rama `main` para producción, una rama `develop` para desarrollo, y se sugiere crear ramas a partir de `develop` para realizar cambios, o mejoras, e ir integrando dichos cambios a `develop`, y finalmente a `main`.

### 3.2 Crear una cuenta de servicio privilegiada para Terraform


### 3.3 Pre-requisitos de GitHub Actions

#### 3.3.1 Entornos de GitHub

Necesita crear los siguientes [entornos](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment) en su repositorio:

- development
- production

Se debe crear una nueva cuenta de servicio (y una clave de cuenta de servicio) para otorgar acceso privilegiado a Terraform. Para ello, consulte esta [documentación](https://cloud.google.com/iam/docs/service-accounts-create)

Roles necesarios: Administrador (consulte [cómo administrar el acceso a las cuentas de servicio](https://cloud.google.com/iam/docs/manage-access-service-accounts))

A continuación, deberá crear un depósito para almacenar el estado de Terraform de forma segura. Consulte la siguiente [documentación](https://cloud.google.com/docs/terraform/resource-management/store-state) para
almacenar el estado en un backend remoto.

Una vez que el depósito ha sido creado, reemplace el nombre del depósito en el archivo `infra/provider.tf` en la línea 9.

```tf
  backend "gcs" {
    bucket = "<SET_THE_BUCKET_NAME>"
    prefix = "terraform/state"
  }
```

Además, se deben crear los siguientes [secretos de entorno](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment#environment-secrets):

- GCP_PROJECT_ID: <the project id where you want to deploy the infrastructure>
- GCP_REGION: <the region where you want to deploy the infrastructure>
- GCP_CREDENTIALS_JSON: <el contenido json de la cuenta de servicio que ha creado con permisos suficientes para crear/administrar los recursos de infraestructura>

Una vez que estas configuraciones estén listas, los activadores de GitHub Workflows se activarán cuando se cumplan las reglas establecidas en los archivos `.github/workflows/ci.yaml` y `.github/workflows/cd.yaml`

