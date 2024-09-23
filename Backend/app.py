from flask import Flask, request
from firebase import login, signup

app = Flask(__name__)

@app.route('/')
def home():
    return "Hello, Flask!"

if __name__ == '__main__':
    app.run(debug=True)

@app.route('/login', methods=['POST'])
def login_route():
    data = request.json
    email = data.get('email')
    password = data.get('password')
    if not email or not password:
        return "Email and password are required", 400
    result = login(email, password)
    return result

@app.route('/signup', methods=['POST'])
def signup_route():
    data = request.json
    email = data.get('email')
    password = data.get('password')
    if not email or not password:
        return "Email and password are required", 400
    result = signup(email, password)
    return result