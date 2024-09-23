from flask import Flask
from firebase import login, signup
from flask import request

app = Flask(__name__)

@app.route('/')
def home():
    return "Hello, Flask!"

if __name__ == '__main__':
    app.run(debug=True)


@app.route('/login', methods=['POST'])
def login_route():
    email = request.form.get('email')
    password = request.form.get('password')
    result = login(email, password)
    return result
