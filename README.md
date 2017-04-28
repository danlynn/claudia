## Supported tags and respective `Dockerfile` links

+ [`2.12.1`,`latest` (2.12.1/Dockerfile)](https://github.com/danlynn/claudia/blob/2.12.1/Dockerfile)
+ [`2.11.0` (2.11.0/Dockerfile)](https://github.com/danlynn/claudia/blob/2.11.0/Dockerfile)
+ [`2.9.0` (2.9.0/Dockerfile)](https://github.com/danlynn/claudia/blob/2.9.0/Dockerfile)


This image contains everything you need to have a working development environment for claudia.js projects.  The container's working dir is `/myapp` so that you can setup a volume mapping your laptop's project dir to `/myapp` in the container.

claudia 2.11.0 + node 4.3.2 + npm 2.14.12 + aws-cli 1.11.75 + python 2.7.9 + cwtail

![claudia.js logo](https://raw.githubusercontent.com/danlynn/claudia/master/claudiajs.png)


## How to use

Basically, there is an `install-claudia-app-template` command in the container which will add some basic config and shortcut scripts to your lambda project's directory.  You will be using the added `bash` shortcut to launch a shell in which you can execute all your Claudia.js related commands.  You will basically leave this bash shell open during development.  It has your project directory from you laptop mapped to `/myapp` in the container allowing you do to all your development with your normal editor and tools then you can use the bash shell for Claudia.js related commands.  There is also a helpful `logs` shortcut that will actively tail the lambda logs.

## hello-world tutorial

### 1. Initialize the project

Assuming that you already have [Docker installed](https://www.docker.com/community-edition) on your laptop, you can setup a new claudia project using this docker container by simply executing the following commands:

```
$ mkdir hello-world
$ cd hello-world
$ docker run -ti -v "$(pwd):/myapp" danlynn/claudia:latest install-claudia-app-template
```

This will add the following structure in your laptop's current directory:

```
.aws
    config
    credentials
.claudia-version
.gitignore
TEMPLATE-README.md
bash
logs
synctime
```

This gives you some aws config files that will be specific to only this project.  It also gives you the `bash` and `logs` commands.  Note that you can alternatively provide a specific claudia version by replacing `latest` in the command above with a Claudia.js version like `2.9.0`.  If any of these files already exist in the current directory (like `.gitignore` or `.aws/credentials`) then they will NOT be overwritten by the template files.

### 2. Configure aws credentials and region

Next modify the `.aws/credentials` file adding your own `aws_access_key_id` and `aws_secret_access_key`.

```
[claudia]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_ACCESS_SECRET
```

By default, the `.aws/config` file sets the aws region to 'us-east-1'.  However, you can feel free to make whatever changes you desire.

### 3. Create hello-world lambda

You are now ready to create a claudia.js lambda function.  This is adapted from the [Hello World AWS Lambda function](https://www.claudiajs.com/tutorials/hello-world-lambda.html) tutorial on the Claudia.js website.

1. Create a new file named `hello-world.js` in your laptop's project folder to hold your lambda function.

2. Copy the following into the JS file:

   ```
   exports.handler = function (event, context) {
      context.succeed('hello world');
   };
   ```

3. Launch the claudia container bash shell:

   ```
   $ ./bash
   ```
   
   Don't forget the preceding `./` so that you execute the shortcut instead of launching a local bash shell.
   
4. Create a `package.json` file with the `npm init` command.  You can simply enter "hello-world" at the 'name' prompt then hit enter accepting the defaults for all subsequent fields:

   ```
   root@3aeafad121e8:/myapp# npm init
   
   name: (myapp) hello-world
   version: (1.0.0) 
   description: 
   entry point: (hello-world.js) 
   test command: 
   git repository: 
   keywords: 
   author: 
   license: (ISC) 
   About to write to /myapp/package.json:
   
   {
     "name": "hello-world",
     "version": "1.0.0",
     "description": "",
     "main": "hello-world.js",
     "scripts": {
       "test": "echo \"Error: no test specified\" && exit 1"
     },
     "author": "",
     "license": "ISC"
   }
   
   Is this ok? (yes) 
   npm info init written successfully
   npm info ok 
   ```
      
5. Deploy the lambda function to aws using claudia in the container shell:

   ```
   root@3aeafad121e8:/myapp# claudia create --region us-east-1 --handler hello-world.handler
   
   {
     "lambda": {
       "role": "hello-world-executor",
       "name": "hello-world",
       "region": "us-east-1"
     }
   }
   ```

   This command will iterate through a series of steps then output a json response as shown above.
   
   Note that even though we have specified the region in our project's `.aws/config` file, the `claudia create` command requires it to be explicitly specified in the command params.
   
   The `--handler` value is made up of our main lambda function's filename and the name of the exported function.  In our case the "hello-world.handler" value gets "hello-world" from `hello-world.js` and "handler" from `exports.handler = function` in that file's source.
   
### 4. Test hello-world lambda

The lambda function can now be tested from the container bash shell using:

```
root@3aeafad121e8:/myapp# claudia test-lambda

{
  "StatusCode": 200,
  "Payload": "\"hello world\""
}
```

This command will output the response from running the lambda function.

Note that the `claudia test-lambda` command does not need you to specify which lambda function to execute because claudia stored that information into `claudia.json` when you deployed it.

## Making a change and redeploying

Modify the contents of your `hello-world.js` file as follows (add the word "again"):

```
exports.handler = function (event, context) {
  context.succeed('hello again world');
};
```

Then redeploy the code changes to aws with:

```bash
root@3aeafad121e8:/myapp# claudia update

updating Lambda	lambda.updateFunctionCode	FunctionName=hello-world
{
  "FunctionName": "hello-world",
  "FunctionArn": "arn:aws:lambda:us-east-1:018867421119:function:hello-world:2",
  "Runtime": "nodejs4.3",
  "Role": "arn:aws:iam::018867421119:role/hello-world-executor",
  "Handler": "hello-world.handler",
  "CodeSize": 1928,
  "Description": "",
  "Timeout": 3,
  "MemorySize": 128,
  "LastModified": "2017-04-12T03:18:41.060+0000",
  "CodeSha256": "XzMlQlas26zQep/9A3faz9DTBkctIsOdev5kppZNpBQ=",
  "Version": "2",
  "KMSKeyArn": null
}
```

And test again with:

```bash
root@3aeafad121e8:/myapp# claudia test-lambda
{
  "StatusCode": 200,
  "Payload": "\"hello again world\""
}

```

## Tailing the lambda logs

The `logs` shortcut script that was installed when you ran `install-claudia-app-template` can be used to tail the lambda logs for your lambda function directly on the command line.

When in a terminal window on your laptop, from your project's directory, simply type `./logs` to start tailing your lambda function's logs:

```bash
$ ./logs

Mon Apr 10 22:05:00 UTC 2017
[Thu Apr 06 2017 20:19:28 GMT+0000 (UTC)] START RequestId: 55cef719-1b06-11e7-8c6d-bb2dae4ced5e Version: $LATEST
[Thu Apr 06 2017 20:19:28 GMT+0000 (UTC)] END RequestId: 55cef719-1b06-11e7-8c6d-bb2dae4ced5e
[Thu Apr 06 2017 20:19:28 GMT+0000 (UTC)] REPORT RequestId: 55cef719-1b06-11e7-8c6d-bb2dae4ced5e	Duration: 10.81 ms	Billed Duration: 100 ms 	Memory Size: 128 MB	Max Memory Used: 16 MB	
[Mon Apr 10 2017 18:31:18 GMT+0000 (UTC)] START RequestId: e2fc86ca-1e1b-11e7-a0c2-25da365b9505 Version: $LATEST
[Mon Apr 10 2017 18:31:18 GMT+0000 (UTC)] END RequestId: e2fc86ca-1e1b-11e7-a0c2-25da365b9505
[Mon Apr 10 2017 18:31:18 GMT+0000 (UTC)] REPORT RequestId: e2fc86ca-1e1b-11e7-a0c2-25da365b9505	Duration: 14.15 ms	Billed Duration: 100 ms 	Memory Size: 128 MB	Max Memory Used: 16 MB	
[Mon Apr 10 2017 18:38:35 GMT+0000 (UTC)] START RequestId: e765b83c-1e1c-11e7-bf14-85f7ae2e31d9 Version: $LATEST
[Mon Apr 10 2017 18:38:35 GMT+0000 (UTC)] END RequestId: e765b83c-1e1c-11e7-bf14-85f7ae2e31d9
[Mon Apr 10 2017 18:38:35 GMT+0000 (UTC)] REPORT RequestId: e765b83c-1e1c-11e7-bf14-85f7ae2e31d9	Duration: 37.22 ms	Billed Duration: 100 ms 	Memory Size: 128 MB	Max Memory Used: 16 MB	
```

Type `ctrl-C` to stop tailing the logs.  The output will be updated about every 5 seconds as new log entries appear.

You can also start tailing the logs while in the docker container's bash session by simply typing `logs` from any directory:

```bash
root@ea36c452ab85:/myapp# logs

[Thu Apr 06 2017 20:19:28 GMT+0000 (UTC)] START RequestId: 55cef719-1b06-11e7-8c6d-bb2dae4ced5e Version: $LATEST
[Thu Apr 06 2017 20:19:28 GMT+0000 (UTC)] END RequestId: 55cef719-1b06-11e7-8c6d-bb2dae4ced5e
[Thu Apr 06 2017 20:19:28 GMT+0000 (UTC)] REPORT RequestId: 55cef719-1b06-11e7-8c6d-bb2dae4ced5e	Duration: 10.81 ms	Billed Duration: 100 ms 	Memory Size: 128 MB	Max Memory Used: 16 MB	
[Mon Apr 10 2017 18:31:18 GMT+0000 (UTC)] START RequestId: e2fc86ca-1e1b-11e7-a0c2-25da365b9505 Version: $LATEST
[Mon Apr 10 2017 18:31:18 GMT+0000 (UTC)] END RequestId: e2fc86ca-1e1b-11e7-a0c2-25da365b9505
[Mon Apr 10 2017 18:31:18 GMT+0000 (UTC)] REPORT RequestId: e2fc86ca-1e1b-11e7-a0c2-25da365b9505	Duration: 14.15 ms	Billed Duration: 100 ms 	Memory Size: 128 MB	Max Memory Used: 16 MB	
[Mon Apr 10 2017 18:38:35 GMT+0000 (UTC)] START RequestId: e765b83c-1e1c-11e7-bf14-85f7ae2e31d9 Version: $LATEST
[Mon Apr 10 2017 18:38:35 GMT+0000 (UTC)] END RequestId: e765b83c-1e1c-11e7-bf14-85f7ae2e31d9
[Mon Apr 10 2017 18:38:35 GMT+0000 (UTC)] REPORT RequestId: e765b83c-1e1c-11e7-bf14-85f7ae2e31d9	Duration: 37.22 ms	Billed Duration: 100 ms 	Memory Size: 128 MB	Max Memory Used: 16 MB	
```

## Troubleshooting

Sometimes, you will receive a message like this when executing commands that interact with aws:
   
```
An error occurred (InvalidSignatureException) when calling the FilterLogEvents operation: Signature expired: 20170406T184748Z is now earlier than 20170406T190807Z (20170406T191307Z - 5 min.)
```
   
When this occurs, you can correct the situation by simply synchronizing the clock of the container with the `synctime` shortcut:
   
```
$ ./synctime
```

Note that both the `bash` and `logs` shortcut scripts call `synctime` before launching the docker container.  So, chances are that you won't need to be calling `synctime` yourself.

Another way to avoid sync issues when executing commands that interact with aws is to add the following at the top of your lambda function before the export:

```
// Fix: InvalidSignatureException: Signature expired: 20170223T053320Z is now earlier than 20170223T150109Z (20170223T150609Z - 5 min.)
const AWS = require('aws-sdk');
AWS.config.update({
  region: 'us-east-1',
  correctClockSkew: true
});
```
