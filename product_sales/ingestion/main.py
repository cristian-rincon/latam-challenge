import json
from google.cloud import pubsub_v1
from flask import jsonify, request
import os

# Define variables de entorno para el proyecto y el nombre del topic
PROJECT_ID = os.getenv('GCP_PROJECT')
PUBSUB_TOPIC = os.getenv('PUBSUB_TOPIC')

def ingest_data(request):
    """Cloud Function para enviar datos dinámicos a una suscripción de Pub/Sub"""
    
    # Verificar si la solicitud es POST y tiene un cuerpo
    if request.method != 'POST':
        return jsonify({"error": "Método no permitido. Usa POST."}), 405

    try:
        # Leer el cuerpo de la solicitud y convertir a JSON
        request_json = request.get_json()
        
        # Validar que el cuerpo de la solicitud tenga los campos necesarios
        required_fields = ["product_id", "product_name", "category", "unit_price", "supplier"]
        for field in required_fields:
            if field not in request_json:
                return jsonify({"error": f"Falta el campo requerido: {field}"}), 400
        
        # Convertir los datos a formato JSON
        message_json = json.dumps(request_json)
        message_bytes = message_json.encode('utf-8')

        # Publicar mensaje en el topic de Pub/Sub
        publisher = pubsub_v1.PublisherClient()
        topic_path = publisher.topic_path(PROJECT_ID, PUBSUB_TOPIC)

        future = publisher.publish(topic_path, data=message_bytes)
        future.result()  # Esperar a que el mensaje sea publicado

        return jsonify({"message": "Mensaje publicado con éxito."}), 200

    except Exception as e:
        print(f'Error al publicar mensaje: {e}')
        return jsonify({"error": str(e)}), 500
