Reusable Terraform VPC Module with Multi-Environment Deployment

# Objective
Design and publish a versioned, reusable Terraform network module that provisions a complete VPC foundation, then consume it across two isolated environments (dev and prod) driven entirely by environment-specific variable files.

## Scope

The network module provisions a VPC with public and private subnets distributed across two Availability Zones, associated route tables, an Internet Gateway, and NAT for private subnet egress. All environment-varying inputs (CIDR ranges, AZ selection, tags) are exposed as module variables with no hardcoded values.

The root configuration consumes the module twice, with dev.tfvars and prod.tfvars supplying non-overlapping CIDR blocks and environment-specific parameters, demonstrating clean reuse without duplicating resource definitions.

## Quality Gates

A pre-commit hook enforces terraform validate and tflint on every commit to catch syntax, configuration, and linting issues before they reach version control.

## Deliverable

A Git-tagged module (v0.1.0) referenceable by source URL with ?ref=v0.1.0, allowing downstream configurations to pin against a stable, versioned release.

