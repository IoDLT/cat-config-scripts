# Catapult Shell Node Configuration Scripts

##### Table of Contents

[Introduction](#Introduction)

[How-To](#How-To)

[Concepts](#Concepts)

<hr>

## Introduction

_NOTE: These scripts are for configuring a Catapult node after it has already been compiled._

These scripts were originally created by core developer Jaguar0625. I took them and added a few extra features to enhance the user experience, as well as some additional documentation so you can actually utilize these and _understand what you're doing_. These scripts:

- Reset your Catapult node.
- Configure your node for `peer`, `api` or `dual` mode (more detail below).
- Configure your node with the necessary extensions for each respective mode.
- Configure `resources` necessary catapult-server paths.
- Generate a nemesis block properties file with boot key and paths.
- Generate mosaic ids for the given public key.
- Generate a list of harvester keys and addresses, and configure the nemesis block file with them.
- Generate a unique generation hash for each instance of the network.
- Generate the nemesis block, 64 byte hashes.dat, and a fresh `data` directory.
- Generate self-signed TLS certificates for the server

This is the setup that is required to get a Catapult node up and running. Luckily, these scripts do it in just a few steps. :)

## How-To

### Necessary Environment Variables

Go to your `~/.bash_rc` (or `~/.bash_profile` on mac) and add these lines to the bottom:

```
export CATAPULT_SERVER_ROOT=<where your catapult server root is>
export CATAPULT_BIN=<where your catapult build files are>
```

Then run `source ~/.bash_rc`.

### Directory Structure
***
In order for these to work, a certain directory structure has to be adopted. This structure is similar to the [catapult-service-bootstrap](https://github.com/tech-bureau/catapult-service-bootstrap):

```
catapult-node-data/
├── data
├── nemesis
├── resources
├── scripts
├── seed
├── certs
└──   
```

As you can probably guess, our node configuration scripts will end up being inside of the `scripts/` directory.

Clone this repo: `git clone https://github.com/IoDLT/cat-config-scripts.git`

Firstly, create a directory to house the above structure:

```
mkdir catapult-node && cd catapult-node
mkdir -p data nemesis resources scripts seed certs
```

Now, go ahead and move the `cat-config/` found in this repo over to `catapult-node-data/scripts`

If you have a remote mongoDB host then you would also want to set the `REMOTE_MONGODB_HOST` environment variable.

```
export REMOTE_MONGODB_HOST=1.1.1.1:27018

```

### Running `reset.sh`
***
`reset.sh` will reset any existing node configuration, as well as, configure a new node. Its usage is as follows, keep in mind the scripts utilize the `zsh` shell. Make sure you are in `catapult-node-data/` when you run this:

`zsh scripts/cat-config/reset.sh --<node_option> <node_type>`

Let's break this down:

- `node_type` - This argument tells the script which kind of node to configure. There are three node types in catapult: `dual`, `peer`, and `api`. An explanation for each can be found in #concepts.

- `node_option` - This argument tells the script whether to configure the node as a completely new node, connect your node to an existing chain, or join the Foundation network. There are three switches respectively:

      	--local - zsh scripts/cat-config/reset.sh --local <node_type>
	
	This starts a single, independent local node.  It has its own generation hash.

      	--official <node_type> 

	This prepares node that is ready to connect to the Foundation, main testnet. 

      	--existing - zsh scripts/cat-config/reset.sh --existing <node_type> <template_name>.  
		  
	Provided from a template, resources are loaded to join an existing network. You may add your own template by copying the structure in `templates/testnet`.

Once you have your arguments in the correct order, you can simply run the script and watch it go! If all went well, you should see the nemesis block information at the bottom of the output. At any time if you want to change your node configuration, you may run `reset.sh` with different settings. **Keep in mind that it will reset your chain!**

### Configure `config-harvesting.properties`
***
Before starting your node, take a private key from `harvester_addresses.txt` (it gets generated during `reset.sh`) and go into `resources/config-harvesting.properties`. Set the `harvestKey` to the private key you copied from `harvester_addresses.txt`.

### Starting Catapult with `start.sh`
***
To start a Catapult service (`server` or `broker`), run this script from `scripts/cat-config`:

`zsh scripts/cat-config/start.sh <server | broker> --force`

Let's break this down:

- `server | broker` - This argument allows you to pass in the type of service you would like to start. `server` starts up your actual node, while `broker` will start Catapult's broker service.

  - Starting the server: `zsh scripts/cat-config/start.sh server <path_to_catapult-server_src> --force`

  - Starting the broker: `zsh scripts/cat-config/start.sh broker <path_to_catapult-server_src> --force`

- `--force` - This argument deletes the `.lock` file that is usually generated in `data/`. You may, or may not, need to run this argument.

## Concepts

### Catapult Extensions
***
Extensions in Catapult are essentially modules that add features to the otherwise bare `catapult-server`. They range from extensions that are critical like consensus and networking to optional extensions like zmq messaging and other API conveniences.

Extensions are _not_ meant to the confused with **plugins**. Extensions modify the core server, whereas plugins introduce new and different ways to alter the chain's state via transactions.

### Catapult Node Types
***
These scripts introduce several interesting concepts about Catapult nodes. If you noticed, we are actually able to generate configurations for _three_ types of nodes:

- `peer` nodes are the "bare minimum" version of a Catapult node. It does not load API extensions like `extension.filespooling` or `extension.partialtransaction`, but rather it runs the backbone of the `catapult-server` architecture that handles consensus and networking. `peer` nodes require a few extensions in order to be operational.

- `api` nodes introduce convenience APIs to interface with a given peer node. They load extensions like `extension.filespooling` to queue messages from the node to a broker, and `extension.partialtransaction` to enable the API node to identify and store partial aggregate bonded transactions.

- `dual` nodes combine a `peer` node and `api` node into a single server instance. It loads extensions required for both `peer` and `api` nodes. If you chose this option in the script, you can see inside of your `config-node.properties` file that the node is set for both types.

###
