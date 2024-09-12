import os
from google.cloud import bigquery
from flask import jsonify

# Definir variables de entorno
PROJECT_ID = os.getenv('GCP_PROJECT')
DATASET_ID = os.getenv('BIGQUERY_DATASET')
TABLE_ID = os.getenv('BIGQUERY_TABLE')

def fetch_data(request):
    """Cloud Function para consultar datos desde BigQuery"""
    
    # Inicializar cliente de BigQuery
    client = bigquery.Client()

    # Definir el nombre completo de la tabla
    table_ref = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"

    # Especificar la consulta SQL
    query = f"""
        SELECT product_id, product_name, category, unit_price, supplier
        FROM `{table_ref}`
        LIMIT 10
    """

    # Ejecutar la consulta
    try:
        query_job = client.query(query)  # Ejecutar la consulta
        results = query_job.result()     # Obtener los resultados

        # Convertir los resultados a un formato JSON
        data = []
        for row in results:
            data.append({
                "product_id": row.product_id,
                "product_name": row.product_name,
                "category": row.category,
                "unit_price": row.unit_price,
                "supplier": row.supplier
            })

        return jsonify(data), 200

    except Exception as e:
        print(f'Error al consultar BigQuery: {e}')
        return jsonify({"error": str(e)}), 500
