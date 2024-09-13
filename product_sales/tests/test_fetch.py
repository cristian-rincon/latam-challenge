import json
import unittest
from unittest.mock import MagicMock, patch

from flask import Flask

from fetch.main import fetch_data  # Importa la función que creaste


class TestCloudFunction(unittest.TestCase):

    @patch("fetch.main.bigquery.Client")  # Mock BigQuery client
    def test_fetch_data(self, mock_bigquery_client):
        # Simular los resultados de la consulta de BigQuery
        mock_query_job = MagicMock()
        mock_results = [
            MagicMock(
                product_id=1,
                product_name="Product A",
                category="Category 1",
                unit_price=10.5,
                supplier="Supplier X",
            ),
            MagicMock(
                product_id=2,
                product_name="Product B",
                category="Category 2",
                unit_price=20.0,
                supplier="Supplier Y",
            ),
        ]
        mock_query_job.result.return_value = mock_results
        mock_bigquery_client.return_value.query.return_value = mock_query_job

        # Crear una aplicación Flask de prueba para simular solicitudes HTTP
        app = Flask(__name__)

        with app.test_request_context("/fetch_data"):
            response, status_code = fetch_data(None)

            # Verificar que la función devolvió el estado correcto
            self.assertEqual(status_code, 200)

            # Convertir la respuesta a JSON para verificar su contenido
            data = json.loads(response.get_data(as_text=True))

            # Verificar que la respuesta contenga los datos esperados
            self.assertEqual(len(data), 2)
            self.assertEqual(data[0]["product_id"], 1)
            self.assertEqual(data[0]["product_name"], "Product A")
            self.assertEqual(data[1]["product_name"], "Product B")
