import os

from flask import jsonify
from google.cloud import bigquery

# Env variables
PROJECT_ID = os.getenv("GCP_PROJECT")
DATASET_ID = os.getenv("BIGQUERY_DATASET")
TABLE_ID = os.getenv("BIGQUERY_TABLE")


def fetch_data(request):
    """Cloud Function para consultar datos desde BigQuery"""

    # Initialize the BigQuery client
    client = bigquery.Client()

    # Define the table reference
    table_ref = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"

    # Especify the query
    query = f"""
        SELECT product_id, product_name, category, unit_price, supplier
        FROM `{table_ref}`
        LIMIT 10
    """

    # Execute the query
    try:
        query_job = client.query(query)  # Execute the query
        results = query_job.result()  # Get the results

        # Convert the results to a list of dictionaries
        data = []
        for row in results:
            data.append(
                {
                    "product_id": row.product_id,
                    "product_name": row.product_name,
                    "category": row.category,
                    "unit_price": row.unit_price,
                    "supplier": row.supplier,
                }
            )

        return jsonify(data), 200

    except Exception as e:
        print(f"Error al consultar BigQuery: {e}")
        return jsonify({"error": str(e)}), 500
