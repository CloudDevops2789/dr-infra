# IRE Shared TGW Connectivity — Demo Speech

## Introduction

“Today I’ll walk through how we connected our Isolated Recovery Environment to the enterprise network using Transit Gateway peering, and then show how we’ve reduced that connectivity to the specific recovery subnet that needs it.

I have two existing Git branches ready: one with the original broader connectivity configuration, and one with the restricted configuration. I’m not editing any Terraform during this demo. I’ll show the original behavior, apply the already-prepared hardening changes through AAP, and repeat the connectivity tests.”

## Architecture diagram

“Starting from the right of this diagram, our on-premises network connects through the existing site-to-site VPN into the enterprise Shared Transit Gateway. That Shared TGW peers with our dedicated IRE Transit Gateway.

Inside IRE, we’ve separated the environment into Recovery Access, Core Recovery, Protected Data, and Inspection VPCs. Recovery Access is our administrative entry point. Core Recovery hosts the recovery services that need controlled communication with enterprise systems such as Commvault. Protected Data is where recovered workloads and data services reside. Inspection is where AWS Network Firewall checks traffic on the inspected paths.

The important point is that peering does not directly open every IRE VPC to the enterprise. We control which routes exist, steer permitted traffic through Inspection, and apply firewall and workload security rules.”

## Why a dedicated IRE Transit Gateway?

“Someone may ask why we didn’t connect all of the IRE VPCs directly to the existing enterprise Shared TGW.

We wanted a separate routing and operational boundary for cyber recovery. With a dedicated IRE TGW, we own the IRE-side route tables, control which recovery VPCs talk internally, and decide which subnets can use the external peering path. The enterprise networking team continues to manage its Shared TGW and the existing peering attachment, without us taking ownership of that shared infrastructure.

It also makes the design easier to reuse or rebuild. We can change IRE segmentation without making every internal routing decision dependent on the enterprise Shared TGW. That separation is especially useful during a cyber recovery event, when we want controlled access rather than broad inherited enterprise connectivity.”

## Original broader connectivity

“Here’s the original testing setup. To prove that the end-to-end path worked, we enabled enterprise routes for selected subnet groups across Recovery Access, Core Recovery, and Protected Data.

The Network Firewall policy also had temporary broad PASS rules between the external zone and the IRE VPC zones. And the testing Security Group rules allowed broad inbound traffic. That helped us establish basic reachability, but it was never the intended hardened end state.

I’ll now test connectivity from the enterprise side to our test EC2 instances in each of those VPCs. This gives us a before picture against which to compare the restriction.”

## What Network Firewall and Security Groups do

“Before applying the change, it’s worth separating the three layers.

First, Transit Gateway and VPC route tables decide where packets can go. Second, AWS Network Firewall inspects traffic travelling through our Inspection VPC. We have rules for internal IRE communication as well as separate rules for external enterprise communication. Third, EC2 Security Groups control what actually reaches each workload.

So a firewall PASS rule does not, by itself, create a network path, and a route does not, by itself, authorize an application connection. All three layers have to line up for a test to succeed.”

## Restricted branch and apply

“Now I’m switching to the already-prepared hardening branch. The main change is simple: external peering connectivity is selected only for the `recovery-services` subnet group in Core Recovery.

Recovery Access and Protected Data still retain the internal IRE connectivity they need, but they are no longer deliberately given direct external peering routes. The remotely routed CIDR remains `0.0.0.0/0` for this testing phase; that is a routing destination, not a statement that every inbound connection is permitted.

We’ve also prepared the cleanup of temporary Security Group rules and external firewall permissions. Any remaining broad Commvault rule is a clearly identified temporary test exception until the Commvault team confirms the exact source networks and ports.

The Terraform changes are already prepared. I’ll use AAP to apply the reviewed Platform and Inspection changes in the required sequence.”

## After applying — repeat the tests

“Now I’ll repeat the same tests from the same enterprise-side source to the same EC2 targets.

What we want to demonstrate is that the approved Core Recovery test remains reachable, while the direct enterprise paths to Recovery Access and Protected Data no longer work. If those tests behave as expected, we can correlate that with the removed routes and the firewall and Security Group policies.

A failed ping alone is not proof of isolation, because the instance or its operating-system firewall might simply block ICMP. That’s why we compare the before and after tests using the same endpoints, and check the route tables and firewall logs where available. This demonstration validates the tested ICMP paths, not every possible protocol or application.”

## Why `ire_to_external` remains

“One question that may come up is: if Commvault initiates the connection from on-premises, why do we still have `ire_to_external` in Terraform?

Because a connection needs a return path. When Commvault sends a request to a server in Core Recovery, that server must send its response back through the IRE TGW, Inspection, and the peering connection. `ire_to_external` configures the intended routes from the selected recovery-services route tables towards that external path.

To be precise, those routes can also carry newly initiated outbound traffic. The routes themselves don't distinguish a response from a new connection; stateful firewall rules and Security Groups determine which sessions are allowed. That’s why we retain both routing directions but continue tightening the security policy.”

## Closing

“To summarize, the advantage is not just that the IRE can reach the enterprise. It’s that we can control that connection independently and reduce its scope without redesigning the environment.

We reuse the enterprise’s existing VPN and Shared TGW, maintain our own IRE TGW for routing separation, inspect traffic centrally, and restrict direct external connectivity to the recovery-services subnet group that currently needs it.

This is a meaningful reduction from our initial connectivity test configuration. The remaining hardening task is to replace temporary broad Commvault permissions with confirmed source CIDRs and service ports, and complete application-level and negative-path validation.”
