import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("key.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

def login(email, password):
    try:
        user = firebase_admin.auth.get_user_by_email(email)
        if user.password == password:
            return "Login successful"
        else:
            return "Invalid password"
    except firebase_admin.auth.UserNotFoundError:
        return "User not found"
    except Exception as e:
        return f"An error occurred: {e}"

def signup(email, password):
    try:
        user = firebase_admin.auth.create_user(email=email, password=password)
        return "Registration successful"
    except Exception as e:
        return f"An error occurred: {e}"

