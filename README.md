# EOS Token List Tool

This tool takes an account name as an argument and scans all its
transactions for token transfers or issuance. It then prints the total
balance for each token in text or JSON format.

The tool requires an RPC URL of an EOS node that has the history plugin
enabled and is using wildcard filter. Most of BP nodes do not support
this feature. Here you can find instructions for building your own node
for this purpose: https://bit.ly/2NldDaL

## Installing the software

Packages required for Ubuntu or Debian:

```
sudo apt-get install -y libjson-xs-perl libjson-perl \
 libwww-perl liblwp-protocol-https-perl

mkdir -p $HOME/tools
cd $HOME/tools
git clone https://github.com/cc32d9/eostokenlist.git
``` 

CentOS or RHEL can also be used, and you just need to install required
Perl modules.

## Running the tool

The tool understands several options, and `--acc=ACCOUNTNAME` is
mandatory. It specifies the account name for which we search for tokens
and balances.

With `--rpc=URL` you can choose an EOS node where you send your quieries
to. The URL is listed in `api_endpoint` entry of the BP's `/bp.json`
file.

With `--json`, the tool prints a JSON object with all balances to its
standard output. Without this option, the output is in plain text.

Also `--verbose` option prints all diagnostics messages. This is used
mostly for troubleshooting.

```
# Command-line example
perl /home/bob/tools/eostokenlist/eostokenlist.pl --acc=ACCOUNTNAME
```

## Copyright and License

Copyright 2018 cc32d9@gmail.com

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


## Donations

ETH address: `0x7137bfe007B15F05d3BF7819d28419EAFCD6501E`

EOS account: `cc32dninexxx`

