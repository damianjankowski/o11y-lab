import requests
import dotenv
import os
from uuid import uuid4
from random import randint

if os.path.exists(".env"):
    dotenv.load_dotenv()

URL = os.getenv("HOST")

if __name__ == '__main__':
    for _ in range(10):
        payment = {
            "payment_id": f"{str(uuid4())}",
            "amount": randint(1, 1000),
            "currency": "EUR"
        }

        headers = {
            'Content-Type': 'application/json'
        }

        response = requests.post(URL, json=payment, headers=headers)

        print(response.json())
