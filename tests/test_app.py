import unittest
import json
from app import create_app
from app.config import TestingConfig


class AppTestCase(unittest.TestCase):
    def setUp(self):
        self.app = create_app(TestingConfig)
        self.client = self.app.test_client()
    
    def test_index(self):
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertIn('message', data)
        self.assertIn('version', data)
    
    def test_health_check(self):
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'healthy')
    
    def test_get_data(self):
        response = self.client.get('/api/data')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertIn('items', data)
        self.assertIsInstance(data['items'], list)
    
    def test_post_data(self):
        test_data = {'name': 'Test Item', 'value': 123}
        response = self.client.post(
            '/api/data',
            data=json.dumps(test_data),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, 201)
        data = json.loads(response.data)
        self.assertIn('message', data)
        self.assertEqual(data['data'], test_data)


if __name__ == '__main__':
    unittest.main()
