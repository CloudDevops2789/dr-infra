# AWS IRE Cloud Engineering Call Notes

## Opening

“Just to give a quick context before we get into the asks, our AWS Isolated Recovery Environment (IRE) has separate Recovery Access, Core Recovery and Protected Data zones connected through AWS Transit Gateway (TGW). AWS Client VPN is intended for administrator access into the IRE, while AWS Site-to-Site VPN (S2S VPN) is intended for controlled connectivity between Fairview on-premises networks and the AWS IRE. For today, I mainly want to understand the Fairview-standard process for the Client VPN server certificate and the existing Fairview approach for Site-to-Site VPN, so that we align our Terraform implementation with the established platform standards.”

## Client VPN certificate

“I understand that AWS Client VPN needs a server Transport Layer Security (TLS) certificate, and for the enterprise implementation we do not want to use the self-signed certificate approach we used in testing. Can you confirm whether Fairview already has an AWS Private Certificate Authority (AWS Private CA) that the IRE account is expected to use, and whether that CA is hosted centrally in another AWS account or directly in the IRE account?”

If they ask why this matters, respond: “I mainly want to avoid creating a separate certificate authority just for IRE if Fairview already has an approved enterprise Public Key Infrastructure (PKI) model. We would rather consume the existing trusted certificate service and keep PKI ownership with the appropriate team.”

“I also want to understand the normal ownership model. Does Cloud Engineering normally create the Client VPN certificate in AWS Certificate Manager (ACM) and provide the ACM certificate Amazon Resource Name (ARN) to the workload team, or is the standard model for ACM in the workload account to request a private certificate from the centrally managed AWS Private CA?”

If they ask what you prefer, respond: “From the IRE side, the cleanest model for us is to consume an ACM certificate ARN and avoid manually handling certificate files or private keys. I am flexible on whether Cloud Engineering creates it or whether our Terraform requests it, as long as we follow the Fairview standard.”

“If the Private CA is centrally hosted, is there already an approved cross-account model that allows ACM in the IRE account to request and renew certificates from that CA? I do not need the policy details during this call; I mainly want to know whether this is already a supported Fairview pattern or whether another request is required.”

If they ask what “cross-account” means, respond: “I only mean that the CA may remain in a central security or PKI AWS account while the actual ACM certificate used by Client VPN lives in the IRE AWS account. I am checking whether Fairview already supports that arrangement.”

“One point I want to avoid is receiving a raw private key that we then have to store in Ansible Automation Platform (AAP), Terraform variables or local files. Is the normal Fairview model to let ACM manage the certificate and its private key so that our Terraform only references the ACM certificate ARN?”

If they ask what the private key is, respond: “The certificate is the public identity presented by the VPN service, while the private key is the secret cryptographic material that proves ownership of that certificate. I would prefer AWS to manage that sensitive key material rather than our team storing it.”

“What naming convention should we use for the Client VPN server certificate? Is there a Fairview-standard internal Domain Name System (DNS) name, certificate subject or Subject Alternative Name (SAN) format that we should request rather than inventing our own?”

If they ask what SAN means, respond: “Subject Alternative Name is simply an additional hostname or identity included in a TLS certificate. I am not proposing a value; I want to use whatever Fairview PKI standard already exists.”

“Can you also confirm which AWS Region the ACM certificate should be created in? Our understanding is that the certificate should be available in the same Region as the Client VPN endpoint, so I want to make sure we request it in the correct place.”

“Finally on the certificate lifecycle, who owns renewal and expiry monitoring? Is this automatically handled through ACM and the enterprise Private CA, or does the workload team need to raise renewal requests?”

If they ask why you care about renewal, respond: “Because Client VPN is part of the recovery access path, I want to avoid a situation where the environment exists but the server certificate has expired when we actually need to use it.”

“If the certificate comes from a Fairview private CA, do Fairview-managed administrator laptops already trust that CA chain, or is there anything that has to be distributed to the recovery administrators so that the AWS VPN Client trusts the server certificate?”

If they ask what CA chain means, respond: “It is simply the chain of trust from the server certificate back to Fairview’s trusted certificate authority. I am checking whether managed endpoints already trust it.”

“To get the certificate request moving, what exact information do you need from us? I assume you may need the AWS account, Region, environment, intended certificate name and technical owner, but I would rather follow your standard intake process.”

## Client VPN authentication if it comes up

“The Client VPN user-authentication model is being handled separately with Identity and Security. We had been evaluating Security Assertion Markup Language (SAML) with Multi-Factor Authentication (MFA), and we are also considering the IRE isolation requirement. For this discussion I mainly want to keep that separate from the server TLS certificate, because the Client VPN endpoint requires the server certificate regardless of which approved user-authentication method we finally use.”

If they ask whether you need client certificates, respond: “At this stage the ask is only for the server-side TLS certificate used by the AWS Client VPN endpoint. We are not asking for individual client certificates unless the final authentication design explicitly chooses mutual certificate authentication.”

----------

For the server side, our preference is to request the Client VPN TLS server certificate through AWS Certificate Manager (ACM) in the same Region as the Client VPN endpoint, so that ACM manages the private key and renewal. Can you confirm whether that is the approved Fairview model and whether the required cross-account CA permissions are already in place?

For mutual authentication, each approved administrator/device will have its own key pair and submit a Certificate Signing Request (CSR). We need to understand the Fairview process for submitting those CSRs to the Private CA, which certificate template/profile should be used for client authentication, how the signed client certificates are returned, and how individual client certificates are revoked if a user or device should no longer have access.


## Site-to-Site VPN

“On the AWS Site-to-Site VPN side, I do not want us to invent a different pattern if Fairview already has a standard implementation. Could you walk me through how Fairview normally connects an on-premises location to AWS when Transit Gateway is involved, especially the on-premises device, routing method and the AWS-side handoff?”

“My understanding is that the on-premises side needs a Customer Gateway (CGW), which represents the Fairview router, firewall, Software-Defined Wide Area Network (SD-WAN) appliance or VPN concentrator that establishes the Internet Protocol Security (IPsec) tunnels to AWS. What device normally acts as the Customer Gateway in Fairview, which team owns it, and what public IP address is normally presented to AWS?”

If they ask what you mean by Customer Gateway, respond: “In AWS terminology, the Customer Gateway is the AWS-side representation of the on-premises VPN device. I am asking which Fairview router or firewall actually terminates the two AWS VPN tunnels.”

“Does Fairview normally use Border Gateway Protocol (BGP) for Site-to-Site VPN routing, or does it use static routes? If BGP is the standard, what Autonomous System Number (ASN) is normally used on the on-premises side, and is there already a standard ASN for the AWS Transit Gateway?”

If they ask what BGP is, respond: “BGP is the dynamic routing protocol that allows the on-premises router and AWS to exchange routes automatically. I am not proposing the routing design; I am asking which Fairview standard is already in use.”

“What on-premises Classless Inter-Domain Routing (CIDR) ranges would normally be advertised toward the IRE, and what AWS IRE CIDRs should be advertised back toward on-premises? For the IRE we would prefer to expose only the networks that are actually required for recovery rather than automatically advertising the entire enterprise network.”

If they ask why you want selective CIDRs, respond: “The IRE is intended to be isolated, so the goal is to keep hybrid connectivity limited to the minimum recovery paths instead of recreating normal production connectivity.”

“For an AWS environment with several VPCs behind Transit Gateway, does Fairview normally create the Site-to-Site VPN as a TGW VPN attachment, and is there an existing Fairview implementation we can use as a reference?”

If they ask what a VPN attachment is, respond: “It is simply the Site-to-Site VPN connection attached to Transit Gateway so that TGW can control which AWS networks are reachable. I am checking whether this is the standard Fairview hub-and-spoke pattern.”

“How does Fairview normally handle the TGW route table for a Site-to-Site VPN attachment? Does the VPN attachment have a dedicated TGW route table, and do you generally use route propagation, static routes or a combination?”

If they ask what route propagation means, respond: “It means TGW automatically learns or shares routes from an attachment rather than every route being manually entered. I mainly want to understand whether Fairview prefers automatic propagation or explicit routing for hybrid connectivity.”

“One thing I also want to understand is the existing Fairview standard for inspection. When Site-to-Site VPN traffic enters through TGW, is it normally steered through AWS Network Firewall before it reaches the workload VPCs, or are there approved cases where hybrid traffic bypasses the inspection path?”

If they ask for your design view, respond: “Our current preference for IRE is to keep on-premises connectivity tightly controlled and, where practical, inspected before it reaches recovery workloads. I am not asking you to review our architecture today; I mainly want to know what Fairview already standardizes on so we can align with it.”

“Does Fairview have a standard Internet Key Exchange (IKE) and IPsec profile for AWS Site-to-Site VPN, for example IKE version, encryption algorithms, integrity algorithms, Diffie-Hellman groups and whether Pre-Shared Keys (PSKs) or certificate-based tunnel authentication are normally used?”

If they ask whether you have chosen those values, respond: “No, and I would rather not invent them. I am specifically asking for the Fairview-standard crypto profile so that our AWS configuration matches the on-premises network standard.”

“AWS provides two tunnels for each Site-to-Site VPN connection. Does Fairview normally configure both tunnels, and is failover between them handled using BGP? Also, are both tunnels usually terminated on the same on-premises device or on a redundant pair?”

If they ask why this matters, respond: “I want to make sure we implement the same high-availability pattern Fairview already uses rather than considering one tunnel sufficient.”

“Is there any standard requirement around Maximum Transmission Unit (MTU), Maximum Segment Size (MSS), Network Address Translation Traversal (NAT-T), Dead Peer Detection (DPD), tunnel monitoring or CloudWatch alarms that we should include from the beginning?”

If any of these acronyms cause confusion during the call, respond: “Those are the lower-level VPN operational settings. I do not need to define them myself; I am mainly checking whether Fairview already has a standard template we should consume.”

“Finally, how is DNS normally handled across Fairview Site-to-Site VPN connections? If workloads in AWS need to resolve on-premises names, or vice versa, is Route 53 Resolver the normal pattern, and which team normally owns the required forwarding configuration?”

If they ask what Route 53 Resolver does, respond: “It provides DNS forwarding between AWS and on-premises environments. I am simply checking whether that is Fairview’s normal hybrid DNS approach.”

## If the discussion starts drifting

“Hmm, that is useful context, but I would prefer to keep today focused on the two dependencies we need to unblock: the Fairview process for the Client VPN server certificate and the existing Fairview Site-to-Site VPN standard. We can take any broader IRE architecture review separately.”

“If there is an existing Fairview implementation, Terraform module, network request template or architecture document for either of these, that would probably be the most useful reference for us. We can then make sure our implementation consumes the established standard instead of creating something parallel.”

## Closing recap

“Let me just repeat this back so I make sure I captured the actions correctly. For Client VPN, the approved Private CA is ___, the ACM certificate will be created in ___, the certificate request will be owned by ___, the naming requirement is ___, and renewal is owned by ___. For Site-to-Site VPN, the Fairview Customer Gateway device is ___, routing uses ___, the on-premises ASN is ___, the TGW ASN is ___, the approved CIDRs are ___, the standard IKE/IPsec profile is ___, and the normal TGW and Network Firewall handoff is ___. If you can point us to the existing Fairview reference or request process for those two areas, that gives us everything we need to proceed with the Terraform integration.”
