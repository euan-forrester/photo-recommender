import requests
from requests.exceptions import HTTPError
from usersstoreexception import UsersStoreException

class UsersStoreAPIServer:

    '''
    This class interfaces with the API server to retrieve information about users
    '''

    def __init__(self, host, port):
        self.url_prefix = f"http://{host}:{port}"

    def get_users_to_request_data_for(self, seconds_between_user_data_updates):

        try:
            response = requests.get(f"{self.url_prefix}/users/need-update",
                params={'num-seconds-between-updates': seconds_between_user_data_updates})

            response.raise_for_status()

            response.encoding = "utf-8"

            return response.json()

        except HTTPError as http_err:
            raise UsersStoreException from http_err

    def data_requested(self, user_id):

        try:
            response = requests.put(f"{self.url_prefix}/users/{user_id}/data-requested")

            response.raise_for_status()

            return

        except HTTPError as http_err:
            raise UsersStoreException from http_err

    def data_updated(self, user_id):

        try:
            response = requests.put(f"{self.url_prefix}/users/{user_id}/data-updated")

            response.raise_for_status()

            return

        except HTTPError as http_err:
            raise UsersStoreException from http_err