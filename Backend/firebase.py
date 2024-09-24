import firebase_admin
from firebase_admin import credentials, firestore, auth
import firebase_admin.auth as admin_auth
from datetime import timedelta
import json

cred = credentials.Certificate("key.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

def login(email, password):
    try:
        if not email:
            raise ValueError("Email must be a non-empty string.")
        user = admin_auth.get_user_by_email(email)
        custom_token = auth.create_custom_token(user.uid)
        id_token = exchange_custom_token_for_id_token(custom_token)
        
        return "Login successful", id_token
    except ValueError as e:
        return str(e), None
    except Exception as e:
        return f"Login: An error occurred: {e}", None

def exchange_custom_token_for_id_token(custom_token):
    import requests

    # Firebase Auth REST API endpoint for token exchange
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key={FIREBASE_WEB_API_KEY}"

    # Payload for the POST request
    payload = json.dumps({
        "token": custom_token,
        "returnSecureToken": True
    })

    # Headers for the request
    headers = {
        "Content-Type": "application/json"
    }

    try:
        # Make the POST request to Firebase Auth API
        response = requests.post(url, headers=headers, data=payload)
        response.raise_for_status()  # Raises an HTTPError for bad responses

        # Extract the ID token from the response
        data = response.json()
        id_token = data.get("idToken")

        if not id_token:
            raise ValueError("ID token not found in the response")

        return id_token

    except requests.RequestException as e:
        print(f"An error occurred while exchanging the token: {e}")
        return None

def signup(email, password):
    try:
        user = auth.create_user(email=email, password=password)
        custom_token = auth.create_custom_token(user.uid)
        id_token = exchange_custom_token_for_id_token(custom_token)
        return "Registration successful", id_token
    except Exception as e:
        return f"An error occurred: {e}", None

def create_group(group_name, group_code, id_token):
    if len(group_code) < 6:
        return "Group code must be at least 6 characters long"
    
    try:
        # Verify the ID token
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        
        group_ref = db.collection('groups').document(group_code)
        group_ref.set({
            'name': group_name,
            'code': group_code,
            'created_by': uid
        })
        return "Group added successfully"
    except auth.InvalidIdTokenError:
        return "Invalid ID token"
    except Exception as e:
        return f"An error occurred: {e}"

def verify_token(id_token: str):
    try:
        decoded_claims = auth.verify_id_token(id_token)
        uid = decoded_claims['uid']
        print("User ID:", uid)
        return {"uid": uid}  # ID token is valid
    except auth.InvalidIdTokenError as e:
        print("Invalid ID token:", e)
        return {"message": "Invalid ID token"}
    except Exception as e:
        print("An error occurred:", e)
        return {"message": f"An error occurred: {e}"}

# Example usage
res, id_token = login("maxpintchouk4321@gmail.com", "TestPass123!")
print(res, id_token)

if id_token:
    verify_result = verify_token(id_token)
    print(verify_result)
    
    group_result = create_group("My Group", "GROUP123", id_token)
    print(group_result)