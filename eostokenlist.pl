## Tool to display all tokens for an EOS account
#
# Copyright 2018 cc32d9@gmail.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


use strict;
use warnings;
use Getopt::Long;
use JSON;
use LWP::UserAgent;
use HTTP::Request;

my $account;
my $rpcurl = 'http://eu1.eosdac.io';
my $verbose;
my $out_json;


{
    my $ok = GetOptions
        ('acc=s'        => \$account,
         'rpc=s'        => \$rpcurl,
         'json'         => \$out_json,
         'verbose'      => \$verbose);


    if( not $ok or not $account or scalar(@ARGV) > 0 )
    {
        error("Usage: $0 --acc=ACCOUNT [OPTIONS]",
              "Options:",
              "  --acc=ACCOUNT   EOS account name",
              "  --rpc=URL       \[$rpcurl\] EOS RPC URL",
              "  --json          print results in JSON format",
              "  --verbose       print verbose output");
        exit 1;
    }
}


my $ua = LWP::UserAgent->new(keep_alive => 1);
$ua->timeout(5);
$ua->env_proxy;

{
    my $url = $rpcurl . '/v1/chain/get_info';
    my $resp = $ua->get($rpcurl . '/v1/chain/get_info');
    if( not $resp->is_success )
    {
        error("Cannot access $url: " . $resp->status_line);
        exit 1;
    }

    my $content = $resp->decoded_content;
    my $data = eval { decode_json($content) };
    if( $@ )
    {
        error("Content at $url is not a valid JSON: $content");
        exit 1;
    }

    if( not defined($data->{'server_version'}) )
    {
        error("$url returned invalid data $content");
        exit 1;
    }

    verbose('Retrieved server info',
            'server_version=' . $data->{'server_version'});
}


sub get_actions
{
    my $account = shift;
    my $pos = shift;
    my $offset = shift;

    verbose("get_actions acc=$account pos=$pos offset=$offset");

    my $url = $rpcurl . '/v1/history/get_actions';

    my $req = HTTP::Request->new('POST', $url);
    $req->header('Content-Type' => 'application/json');

    $req->content(encode_json(
                      {
                          'account_name' => $account,
                          'pos' => $pos,
                          'offset' => $offset,
                      }));

    my $resp = $ua->request($req);
    if( not $resp->is_success )
    {
        die("Cannot retrieve transactions for account $account");
    }

    my $content = $resp->decoded_content;
    my $data = eval { decode_json($content) };
    if( $@ )
    {
        die("Content at $url is not a valid JSON: $content");
    }

    if( not defined($data->{'actions'}) )
    {
        die("RPC result does not contain a list of actions: $content");
    }

    if( scalar(@{$data->{'actions'}}) == 0 )
    {
        die("Empty list of actions for $account");
    }

    verbose('got ' . scalar(@{$data->{'actions'}}));
    return $data->{'actions'};
}


sub get_balance
{
    my $account = shift;
    my $code = shift;
    my $symbol = shift;

    verbose("get_balance acc=$account code=$code symbol=$symbol");

    my $url = $rpcurl . '/v1/chain/get_currency_balance';

    my $req = HTTP::Request->new('POST', $url);
    $req->header('Content-Type' => 'application/json');

    $req->content(encode_json(
                      {
                          'account' => $account,
                          'code' => $code,
                          'symbol' => $symbol,
                      }));

    my $resp = $ua->request($req);
    if( not $resp->is_success )
    {
        die("Cannot retrieve $code balance for account $account");
    }

    my $content = $resp->decoded_content;
    my $data = eval { decode_json($content) };
    if( $@ )
    {
        die("Content at $url is not a valid JSON: $content");
    }

    return $data->[0];
}



my @all_actions;
my $last_action = get_actions($account, -1, -1);
$last_action = $last_action->[0];
my $last_seq = $last_action->{'account_action_seq'};
verbose("Last action srequence: $last_seq");


my $seq = 0;

while( $seq <= $last_seq )
{
    my $rcount = $last_seq - $seq;
    $rcount = 50 if $rcount > 50;

    my $acts = get_actions($account, $seq, $rcount);
    
    foreach my $action (@{$acts})
    {
        push(@all_actions, $action);
        if( $action->{'account_action_seq'} > $seq )
        {
            $seq = $action->{'account_action_seq'};
        }
    }

    $seq++;
}

verbose("Retrieved " . scalar(@all_actions) . " actions for $account");


my %contracts;

foreach my $action (@all_actions)
{
    my $at = $action->{'action_trace'};
    my $act = $at->{'act'};
    my $name = $act->{'name'};
    if( ($name eq 'transfer' or $name eq 'issue') and
        ref($act->{'data'}) eq 'HASH' and
        defined($act->{'data'}{'quantity'}) )
    {
        my $issuer = $act->{'account'};
        my $qty = $act->{'data'}{'quantity'};
        my $currency = $qty;
        $currency =~ s/^[0-9.]+\s+//;
        if( not $contracts{$issuer}{$currency} )
        {
            verbose("Found token: contract=$issuer currency=$currency");
            $contracts{$issuer}{$currency} = 1;
        }
    }
}


my %balances;

foreach my $issuer (sort keys %contracts)
{
    printf("Issuer: %s\n", $issuer) unless $out_json;
    foreach my $currency (sort keys %{$contracts{$issuer}})
    {
        my $balance = get_balance($account, $issuer, $currency);
        $balance =~ s/\s+\w+$//;
        $balances{$issuer}{$currency} = $balance;
        printf("  %s %s\n", $balance, $currency) unless $out_json;
    }
}


if( $out_json )
{
    my $jswriter = JSON->new()->utf8(1)->canonical(1)->pretty(1);

    print $jswriter->encode(\%balances);
}

exit 0;






sub error
{
    print STDERR (join("\n", @_), "\n");
}

sub verbose
{
    if($verbose)
    {
        print STDERR (join("\n", @_), "\n");
    }
}
