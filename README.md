## Supported tags and respective `Dockerfile` links

+ [`2.9.1`,`latest` (2.9.1/Dockerfile)](https://github.com/danlynn/claudia/blob/2.9.1/Dockerfile)


This image contains everything you need to have a working development environment for claudia.js projects.  The container's working dir is /myapp so that you can setup a volume mapping your laptop's project dir to /myapp in the container.

claudia 2.9.1 + node 4.8.0/6.10.0 + npm 2.15.11/3.10.10 + bower 1.8.0 + phantomjs 2.1.7 + watchman 3.5.0

![claudia.js logo](https://raw.githubusercontent.com/danlynn/claudiajs/master/claudiajs.png)


## How to use

Basically, there is an init command in the container which will add some basic config and shortcut files to your project directory.  You will be using the `bash` shortcut to launch a shell in which you can execute all your claudia.js related commands.  There is also a `logs` shortcut to display the lambda logs.

### Init the project

Setup a new claudia project using this docker container by simply executing the following on your laptop:

```
$ mkdir claudia-test
$ cd claudia-test
$ docker run -ti -v "$(pwd):/myapp" danlynn/claudia:2.9.1 install-claudia-app-template
```

This will add the following structure in the current directory:

<pre>
.aws
    config
    credentials
.gitignore
bash
logs
</pre>

This gives you some aws config files that will be specific to only this project.  It also gives you the `bash` and `logs` commands.  Note that the version number at the end of this command is important because it sets tag that will be used in the `bash` and `logs` shortcuts.

### Configure aws credentials

Next modify the `.aws/credentials` file adding your own `aws_access_key_id` and `aws_secret_access_key`.

### Create HelloWorld lambda

You are now ready to create a claudia.js app.  This is adapted from the (Hellow World AWS Lambda function)[https://www.claudiajs.com/tutorials/hello-world-lambda.html] tutorial on the claudia.js website.

1. Create a new JS file named 'hello-world.js' to hold your lambda function.

2. Copy the following into the JS file:

   <pre>
   exports.handler = function (event, context) {
      context.succeed('hello world');
   };
   </pre>

3. Optionally synchronize container clock

   Sometimes, you will receive a message like this when executing commands that interact with aws:
   
   <pre>
   An error occurred (InvalidSignatureException) when calling the FilterLogEvents operation: Signature expired: 20170406T184748Z is now earlier than 20170406T190807Z (20170406T191307Z - 5 min.)
   </pre>
   
   When this occurs, you can correct the situation by simply synchronizing the clock of the container with the `synctime` shortcut:
   
   ```
   $ synctime
   ```

4. Launch the claudia container bash shell:

   ```
   $ ./bash
   ```
   
   Don't forget the preceding `./` so that you execute the shortcut instead of launching a local bash shell.
   
5. Create a `package.json` file with the `npm init` command.  You can simply enter "hello-world" at the 'name' prompt then hit enter accepting the defaults for all subsequent fields:

   ```
   root@3aeafad121e8:/myapp# npm init
   
   ...
   
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
      
6. Deploy the lambda function to aws using claudia in the container shell:

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
   
### Test Hello World lambda

The lambda function can now be tested from the container shell using:

```
root@3aeafad121e8:/myapp# claudia test-lambda

{
  "StatusCode": 200,
  "Payload": "\"hello world\""
}
```

This command will output the response from running the lambda function.

Note that the `claudia test-lambda` command does not need you to specify which lambda function to execute because claudia stored that information into `claudia.json` when you deployed it.

### Troubleshooting

Another way to avoid sync issues when executing commands that interact with aws is to add the following at the top of your lambda function before the export:

<pre>
// Fix: InvalidSignatureException: Signature expired: 20170223T053320Z is now earlier than 20170223T150109Z (20170223T150609Z - 5 min.)
const AWS = require('aws-sdk');
AWS.config.update({
  region: 'us-east-1',
  correctClockSkew: true
});
</pre>
