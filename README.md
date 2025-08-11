README: 
-
Godot <-> RabbitMQ <-> Java
-----

This is a sample demo leveraging a conceptual architecture, ideal for a turn-based game with streaming elements (like chat)
------

Due to the ubiquity of AMQ, the elements of this architecture are easily modified with a large number of services and tools.

This solution is tailored for RabbitMQ, due to the various complex API considerations to ensure it's scalable, in specific ways.

This was developed by someone who is a beginner with RabbitMQ, an intermediate with Godot, and a veteran java developer.

This project leverages other people's hard work, notably:
* https://github.com/TheWalruzz/godot-promise
* https://github.com/arnemileswinter/rabbitgd

There are salient changes made to these libraries, contained within. 
Some changes are subtle, some aggressive (Log.gd everywhere, rabbitmq disconnect signaling, arrays of promises, etc) 

This demo requires some userland tooling and basic familiarity with that tooling to execute.
The setup instructions assumes users have: (~ means something like it)

* Docker~
* IntelliJ (2022+)
* Godot 4.1+
* curl~
-----

1. In the Java folder, run:
 

    docker compose up

Note: Rabbit MQ takes awhile and will take over the shell. IntelliJ allows for a new shell via +

2. Load the java project into IntelliJ

Note: the .run configurations should be available as runtime configurations

3. Load dependencies from maven

4. Test build by running maven configuration: my_server 

5. Run Spring configuration: Application

After startup is complete, the application should be running and connected to the docker DB and RabbitMQ.

6. Open the Godot GodotRmqDemo project.
7. Run the Godot GodotRmqDemo project.
8. Checkbox should be enabled. Click connect.


    [controller:48]: Client CONNECTED

Note: When sending a message, if it reached the server, it will reply. GodotRmqDemo will log:

    [controller:58]: sMessage received with payload: { "mtype": "pong" }

9. Click disconnect.


-----

Creating a user that will work, end to end, is a process.

The first step is a simple Create User in the Database, which also creates a user in RMQ.

    POST localhost:8080/server/api/v1/user/create
    {
        "username": "myname",
        "email": "myemail@nowhere.com",
        "cipher": "testtest"
    }

The second step attaches the server to the RabbitMQ user-queue, via an RMQ registry.
Without this, the server will not hear new messages on a queue.

    POST localhost:8080/server/api/v1/user/login
    {
        "username": "myname",
        "cipher": "testtest"
    }

There are some extra APIs on the server for convenience.

-----

Note: If you want to make this better, on the Java side, on the Godot side, submit an issue to discuss or better, make a PR.

Note: If want to work with me on the project built around this design, I'm on reddit.

DISCLAIMER:
There are probably breaking bugs, as this is a stripped down demo of a larger project and will have problems if you stop and start the server or modify data in the DB. This is not production safe by any means.
