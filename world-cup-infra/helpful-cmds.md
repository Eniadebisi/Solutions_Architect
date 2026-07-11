```bash
# Verify the backend bucket exists and is accessible
aws s3 ls s3://world-cup-tfstate --profile world-cup

# List all state files across modules
aws s3 ls s3://world-cup-tfstate --recursive --profile world-cup

# View raw state for a stack (useful for debugging)
aws s3 cp s3://world-cup-tfstate/platform/terraform.tfstate - \
  --profile world-cup | python3 -m json.tool | less

# List all resources tracked in state (from inside the module directory)
terraform state list

# Show details of a specific resource in state
terraform state show aws_vpc.main

# Pull current state to a local file (for inspection)
terraform state pull > local-state-backup.json

# Check if the DynamoDB lock table exists
aws dynamodb describe-table \
  --table-name world-cup-tflock \
  --profile world-cup \
  --query "Table.{Status:TableStatus,Keys:KeySchema}"

# View active locks (should be empty when no apply is running)
aws dynamodb scan \
  --table-name world-cup-tflock \
  --profile world-cup \
  --query "Items"
```