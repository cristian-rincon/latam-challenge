import json
import os

from flask import jsonify, request
from google.cloud import pubsub_v1

# Define variables de entorno para el proyecto y el nombre del topic
PROJECT_ID = os.getenv("GCP_PROJECT")
PUBSUB_TOPIC = os.getenv("PUBSUB_TOPIC")


def ingest_data(request):
    """Cloud Function para enviar datos dinámicos a una suscripción de Pub/Sub"""  # noqa

    # Check if the request method is POST
    if request.method != "POST":
        return jsonify({"error": "Método no permitido. Usa POST."}), 405

    try:
        # Read the JSON data from the request body
        request_json = request.get_json()

        # Validate the required fields
        required_fields = [
            "product_id",
            "product_name",
            "category",
            "unit_price",
            "supplier",
        ]
        for field in required_fields:
            if field not in request_json:
                return (
                    jsonify({"error": f"Falta el campo requerido: {field}"}),
                    400,
                )  # noqa

        # Convert the data to JSON format
        message_json = json.dumps(request_json)
        message_bytes = message_json.encode("utf-8")

        # Publish the message to the Pub/Sub topic
        publisher = pubsub_v1.PublisherClient()
        topic_path = publisher.topic_path(PROJECT_ID, PUBSUB_TOPIC)

        future = publisher.publish(topic_path, data=message_bytes)
        future.result()  # Wait for the message to be published

        return jsonify({"message": "Mensaje publicado con éxito."}), 200

    except Exception as e:
        print(f"Error al publicar mensaje: {e}")
        return jsonify({"error": str(e)}), 500
