import os
import json
import time
import logging

class ExecutionEnvironmentHelper:

    #
    # Gives us information about the current execution environment we're running in: task ID, etc
    #

    @staticmethod
    def get():
        if not "ECS_CONTAINER_METADATA_FILE" in os.environ:
            return ExecutionEnvironmentHelperLocalMachine()
        else:
            return ExecutionEnvironmentHelperECS()


class ExecutionEnvironmentHelperLocalMachine(ExecutionEnvironmentHelper):

    #
    # Gives us information about the local machine we're running on: task ID, etc.
    #

    def get_task_id(self):
        return "local machine"

class ExecutionEnvironmentHelperECS(ExecutionEnvironmentHelper):

    #
    # Gives us information about the ECS cluster we're running in: task ID, etc
    #
    # More info on the file we're reading: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-metadata.html
    #

    MAX_ATTEMPTS_TO_READ_METADATA_FILE = 3

    def __init__(self):

        ecs_container_metadata_file = os.environ.get("ECS_CONTAINER_METADATA_FILE")

        logging.info(f"Attempting to read ECS environment info from {ecs_container_metadata_file}")

        self.task_id = None

        file_successfully_read = False
        num_iterations = 0

        # This metadata file may take a while for the ECS system to write, so might not be completely available the first time we try to read it

        while True:

            with open(ecs_container_metadata_file, "r") as metadata_file:
                text = metadata_file.read()

                metadata = json.loads(text)

                if ("MetadataFileStatus" in metadata) and (metadata["MetadataFileStatus"] == "READY"):

                    task_arn = metadata["TaskARN"] # The task ARN looks like "arn:aws:ecs:us-west-2:012345678910:task/2b88376d-aba3-4950-9ddf-bcb0f388a40c"

                    if task_arn is not None:
                        task_arn_portions = task_arn.split("/")

                        if len(task_arn_portions) > 1:
                            self.task_id = task_arn_portions[1]

                            file_successfully_read = True

            num_iterations += 1

            if file_successfully_read or (num_iterations >= ExecutionEnvironmentHelperECS.MAX_ATTEMPTS_TO_READ_METADATA_FILE):
                break
                
            time.sleep(1.0) # The file is generally ready within one second of the container starting up according to the docs above

        if not file_successfully_read:
            raise RuntimeError(f"Unable to read ECS metadata file {ecs_container_metadata_file} after {num_iterations} attempts")

        logging.info(f"Successfully read ECS environment info in {num_iterations} attempts")
        logging.info(f"Found task ID {self.task_id}")

    def get_task_id(self):
        return self.task_id