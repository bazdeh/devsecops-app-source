from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def home():
    return {
        "status": "Secure",
        "message": "Welcome to your DevSecOps Automated Pipeline!",
        "environment": "Production"
    }

if __name__ == "__main__":
    # Running on 0.0.0.0 to allow traffic inside the container
    app.run(host="0.0.0.0", port=5000)
