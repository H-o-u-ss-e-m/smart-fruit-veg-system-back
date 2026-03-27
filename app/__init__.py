# app/__init__.py
from flask import Flask, jsonify
from flask_cors import CORS
from app.routes import api
from app.config import Config

def create_app():
    app = Flask(__name__)
    CORS(app)  # autorise les requêtes cross-origin (Postman, front-end, etc.)

    app.register_blueprint(api, url_prefix="/api")

    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"error": "Route introuvable."}), 404

    @app.errorhandler(500)
    def server_error(e):
        return jsonify({"error": "Erreur interne du serveur."}), 500

    @app.errorhandler(405)
    def method_not_allowed(e):
        return jsonify({"error": "Méthode HTTP non autorisée."}), 405

    return app