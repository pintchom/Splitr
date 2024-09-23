import firebase_admin
from firebase_admin import credentials, firestore, auth
import firebase_admin.auth as admin_auth

cred = credentials.Certificate("key.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

def login(email, password):
    try:
        if not email:
            raise ValueError("Email must be a non-empty string.")
        user = admin_auth.get_user_by_email(email)
        return "Login successful"
    except ValueError as e:
        return str(e)
    except Exception as e:
        return f"An error occurred: {e}"

def signup(email, password):
    try:
        user = auth.create_user(email=email, password=password)
        return "Registration successful"
    except Exception as e:
        return f"An error occurred: {e}"