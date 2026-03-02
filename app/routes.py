from flask import Blueprint, jsonify, request
from datetime import datetime

main = Blueprint('main', __name__)


@main.route('/')
def index():
    return jsonify({
        'message': 'Welcome to Python Deployment Demo',
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat()
    })


@main.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    }), 200


@main.route('/api/data', methods=['GET', 'POST'])
def data():
    if request.method == 'POST':
        data = request.get_json()
        return jsonify({
            'message': 'Data received',
            'data': data
        }), 201
    
    return jsonify({
        'items': [
            {'id': 1, 'name': 'Item 1'},
            {'id': 2, 'name': 'Item 2'},
            {'id': 3, 'name': 'Item 3'}
        ]
    })
