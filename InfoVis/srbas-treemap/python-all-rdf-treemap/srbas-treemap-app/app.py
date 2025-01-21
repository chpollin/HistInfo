#!/usr/bin/env python3
import os
from flask import Flask, render_template, send_from_directory

app = Flask(__name__)

@app.route("/")
def index():
    # Renders templates/index.html
    return render_template("index.html")

@app.route("/accounts_hierarchy.json")
def serve_hierarchy():
    # Serve the single JSON file from the same folder as app.py
    return send_from_directory(
        os.path.dirname(os.path.abspath(__file__)),
        "accounts_hierarchy.json",
        mimetype="application/json"
    )

if __name__ == "__main__":
    app.run(debug=True, port=5000)
