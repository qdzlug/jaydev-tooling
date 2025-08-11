#!/bin/bash

# Usage: ./ox-inst-vpc.sh <project_id> [--resolve-names]

PROJECT="$1"
RESOLVE_NAMES=false

if [[ -z "$PROJECT" ]]; then
  echo "Usage: $0 <project_id> [--resolve-names]"
  exit 1
fi

if [[ "$2" == "--resolve-names" ]]; then
  RESOLVE_NAMES=true
fi

echo "Listing instances in project: $PROJECT"
$RESOLVE_NAMES && echo "(resolving VPC name and Subnet CIDR block)" || echo "(showing raw IDs)"
echo

oxide instance list --project "$PROJECT" | jq -r '.[].id' | while read -r id; do
  name=$(oxide instance view --instance "$id" | jq -r '.name')

  nic_info=$(oxide instance nic list --instance "$id" | jq '.[0]')
  vpc_id=$(echo "$nic_info" | jq -r '.vpc_id')
  subnet_id=$(echo "$nic_info" | jq -r '.subnet_id')

  if $RESOLVE_NAMES; then
    # Smart project flag handling for VPC
    if [[ "$vpc_id" =~ ^[a-f0-9-]{36}$ ]]; then
      vpc_name=$(oxide vpc view --vpc "$vpc_id" 2>/dev/null | jq -r '.name // .dns_name // "unknown"')
    else
      vpc_name=$(oxide vpc view --project "$PROJECT" --vpc "$vpc_id" 2>/dev/null | jq -r '.name // .dns_name // "unknown"')
    fi

    # Get subnet block (more useful than name)
    subnet_block=$(oxide vpc subnet view --subnet "$subnet_id" 2>/dev/null | jq -r '.ipv4_block // "unknown"')

    echo "$name ($id) => VPC: $vpc_name [$vpc_id] | Subnet: $subnet_block [$subnet_id]"
  else
    echo "$name ($id) => VPC: $vpc_id | Subnet: $subnet_id"
  fi
done