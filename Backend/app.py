from flask import Flask, request
from firebase import login, signup, create_group, authorize_token
from firebase_admin import auth

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
    result, token = login(email, password)
    if result == "Login successful":
        return {"message": "Login successful", "token": token}
    return "Invalid credentials", 401

@app.route('/signup', methods=['POST'])
def signup_route():
    data = request.json
    email = data.get('email')
    password = data.get('password')
    if not email or not password:
        return "Email and password are required", 400
    result, token = signup(email, password)
    if result == "Registration successful":
        return {"message": "Signup successful", "token": token}
    return "Signup failed", 400

@app.route('/create_group', methods=['POST'])
def create_group_route():
    data = request.json
    group_name = data.get('group_name')
    group_code = data.get('group_code')
    id_token = data.get('auth')
    
    if not id_token:
        return "ID token is required", 401
    
    auth_result = authorize_token(id_token)
    if "uid" not in auth_result:
        return auth_result["message"], 401
    
    if not group_name or not group_code:
        return "Group name and group code are required", 400
    
    result = create_group(group_name, group_code)
    return result