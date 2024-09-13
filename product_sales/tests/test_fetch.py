import json
import unittest
from unittest.mock import MagicMock, patch

from flask import Flask

from fetch.main import fetch_data


class TestCloudFunction(unittest.TestCase):

    @patch("fetch.main.bigquery.Client")  # Mock BigQuery client
    def test_fetch_data(self, mock_bigquery_client):
        # Mock the query job and results
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

        # Create a Flask app context for testing
        app = Flask(__name__)

        with app.test_request_context("/fetch_data"):
            response, status_code = fetch_data(None)

            # Verify the response status code
            self.assertEqual(status_code, 200)

            # Convert the response data to JSON format
            data = json.loads(response.get_data(as_text=True))

            # Verify the response data
            self.assertEqual(len(data), 2)
            self.assertEqual(data[0]["product_id"], 1)
            self.assertEqual(data[0]["product_name"], "Product A")
            self.assertEqual(data[1]["product_name"], "Product B")
