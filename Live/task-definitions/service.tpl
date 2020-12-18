[
    {
      "name": "notejam-container",
      "image": "145476053377.dkr.ecr.us-east-1.amazonaws.com/notejam:latest",
      "cpu": 1,
      "memory": 512,
      "essential": true,
      "environment": [
        {
         "name" : "_app_db_user", 
         "value" : "${app_db_user}"
        },
        {
          "name" : "_app_db_pass",
          "value" : "${app_db_pass}"
        },
        {
          "name" : "_app_db_host",
          "value" : "${app_db_host}"
        },
        {
          "name" : "_app_db_port",
          "value" : "${app_db_port}"
        }
      ],
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ]
    }
]