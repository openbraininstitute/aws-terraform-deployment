# Starts ECS tasks on demand based on websocket connections to api gateway.
# ECS task image should listen on 8080 and provide health(GET)/default/shutdown rest endpoints.
# default(POST) endpoint will get forwarded messages from ws connection, it should use
# boto3 apigatewaymanagementapi post_to_connection to send ws messages back.
# Once ws connection is terminated from the client, shutdown(POST) endpoint will be invoked that
# should trigger container exit. Web server in the container should also timeout, so it doesn't
# run forever if the client doesn't close ws connection.
