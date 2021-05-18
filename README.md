# Cardano NFT Auto-Mint System

*Disclaimer: This software is provided as-is with no warranty. I take no responsibility for lost funds due to improper use of this system.*

## What is this software?

This is an automated minting and distribution system for Cardano NFTs. It is designed to allow small creators to automate their sales with as little hassle as possible!

## Requirements

To use this software you will need:
* A fully synced Cardano node using version 1.26.2 (v1.27.0 update coming soon)
* A linux (tested on Ubuntu) system/VPS
* Basic knowledge of Cardano-CLI commands (although most commands will be explained)
* Pre-created policy script and signing key.
* A blockfrost mainnet account and project id.

## Installation

### Step 1 - Download the script
To get started with the system it is first necessary to download the files.

First cd into the directory where your node is running (cardano-my-node if you followed the CoinCashew guide) and then run the following commands:
```
git clone https://github.com/ejane24/Cardano-NFT-Auto-Mint.git
cd Cardano-NFT-Auto-Mint/
ls
```
You should now see 3 files listed, the important one is process.sh.

### Step 2 - Create the payment address
Now we need create a payment address where your buyers will send ada!
First make a folder to contain the keys:
```
mkdir payment
cd payment/
```
Now generate the address keys:
```
cardano-cli address key-gen \
--verification-key-file payment.vkey \
--signing-key-file payment.skey
```
Then we need to build an actual address:
```
cardano-cli address build \
--payment-verification-key-file payment.vkey \
--out-file payment.addr \
--mainnet
```
You can view the address by typing
```
echo $(cat ./payment.addr)
```
You will need this later.

### Step 3 - Update the file
We need to update a few things in process.sh before we can set it running.
```
cd ..
nano process.sh
```
There are several things that need changing. 
Firstly on lines 8-11 we need to add the payment address that we created earlier, as well as add the paths to the payment and policy skey files.
For example:
```
paymentAddr=addr1.....
paymentSignKeyPath=./payment/payment.skey
policySignKeyPath=./policy/policy.skey
scriptPath=./policy/policy.script
```

On line 12 we need to add the address that profits will be sent to:
```
profitAddress=addr1....
```

Now we need to add the blockfrost project id on lines 40 and 43 where it currently says 'Insert here'.

Once you have done that, we need to change how much your NFTs cost. 
To do this, go to line 47 and change 50000000 to your price in **lovelace**.
Next change the number on line 89 to your price in lovelace minus 7500000. This accounts for the 1.5 ada sent back to the user and a 5 ada voluntary donation (more on that later).

#### Voluntary Donations
The script includes a voluntary donation on 5 ada per sale. It is completely up to you whether you leave this in. To remove the donation, simply change line 7 to your own address. You can also increase or decrease this amount as you like but don't forget to update the profit amount. (although there needs to be at least 1 ada for the transaction to work, hence changing the donation address is best).

### Step 4 - Add the metadata

Now we need to make a folder which will contain all the NFT metadata json files. Make sure this is is created in the same directory as process.sh.
```
mkdir metadata
```

Next, simply place all the metadata files (1 for each NFT) in this folder.

### Step 5 - Create a systemctl process
In order for the system to run 24/7 we need to create a systemd service:
```
nano /etc/systemd/system/auto-mint.service
```
Now paste the following into the text editor:
```
[Unit]                                                                                    Description=Corn N Friends Minting Service
Description=Auto Minting Service

[Service]
Environment="CARDANO_NODE_SOCKET_PATH=/root/cardano-my-node/db/socket"
ExecStart=/usr/bin/mint.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```
Save and exit the file and then type:
```
cp process.sh /usr/bin/mint.sh
```
Next we need to start and enable the service:
```
systemctl start auto-mint.service
systemctl enable auto-mint.service
```

If all goes well, typing 
```
systemctl status auto-mint.service
```
Should show no errors.

You are now set up to automatically mint and distribute your NFTs! If you have any questions, you can contact me on Twitter @Crowdano, or discord @Mendrinos#8716
