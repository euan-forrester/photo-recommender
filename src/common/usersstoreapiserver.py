import requests
from requests.exceptions import HTTPError
from usersstoreexception import UsersStoreException

class UsersStoreAPIServer:

    '''
    This class interfaces with the API server to retrieve information about users
    '''

    def __init__(self, host, port):
        self.url_prefix = f"http://{host}:{port}/api"

    def get_users_to_request_data_for(self, seconds_between_user_data_updates):

        try:
            response = requests.get(f"{self.url_prefix}/users/need-update",
                params={'num-seconds-between-updates': seconds_between_user_data_updates})

            response.raise_for_status()

            response.encoding = "utf-8"

            return response.json()

        except HTTPError as http_err:
            raise UsersStoreException from http_err

    def get_users_that_are_currently_updating(self):

        try:
            response = requests.get(f"{self.url_prefix}/users/currently-updating")

            response.raise_for_status()

            response.encoding = "utf-8"

            return response.json()

        except HTTPError as http_err:
            raise UsersStoreException from http_err

    def get_time_to_update_all_data(self, user_id):

        try:
            response = requests.get(f"{self.url_prefix}/users/{user_id}/get-time-to-update-all-data")

            response.raise_for_status()

            response.encoding = "utf-8"

            response_object = response.json()

            return int(response_object['time_in_seconds'])

        except HTTPError as http_err:
            raise UsersStoreException from http_err

    def data_requested(self, user_id, num_puller_requests):

        try:
            response = requests.put(f"{self.url_prefix}/users/{user_id}/data-requested",
                params={'num-puller-requests': num_puller_requests})

            response.raise_for_status()

            return

        except HTTPError as http_err:
            raise UsersStoreException from http_err

    def made_more_puller_requests(self, user_id, num_puller_requests):

        try:
            response = requests.put(f"{self.url_prefix}/users/{user_id}/more-puller-requests",
                params={'num-puller-requests': num_puller_requests})

            response.raise_for_status()

            return

        except HTTPError as http_err:
            raise UsersStoreException from http_err

    def received_puller_responses(self, user_id, num_puller_responses):

        try:
            response = requests.put(f"{self.url_prefix}/users/{user_id}/received-puller-responses",
                params={'num-puller-responses': num_puller_responses})

            response.raise_for_status()

            return

        except HTTPError as http_err:
            raise UsersStoreException from http_err

    def received_ingester_responses(self, user_id, num_ingester_responses):

        try:
            response = requests.put(f"{self.url_prefix}/users/{user_id}/received-ingester-responses",
                params={'num-ingester-responses': num_ingester_responses})

            response.raise_for_status()

            response.encoding = "utf-8"

            response_object = response.json()

            return response_object

        except HTTPError as http_err:
            raise UsersStoreException from http_err

    def request_lock(self, process_id, task_id, lock_duration_seconds):

        try:
            response = requests.put(f"{self.url_prefix}/locks/request",
                params={
                    'process-id':               process_id,
                    'task-id':                  task_id,
                    'lock-duration-seconds':    lock_duration_seconds
                }
            )

            response.raise_for_status()

            response.encoding = "utf-8"

            response_object = response.json()

            return bool(response_object['lock-acquired'])

        except HTTPError as http_err:
            raise UsersStoreException from http_err