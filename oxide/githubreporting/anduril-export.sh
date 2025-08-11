#!/bin/bash
# Fetch ALL items from a GitHub Projects V2 board, including Issues, PRs, and Draft Notes,
# and output a unified dataset with clear item_type and custom_type fields,
# filtering ONLY items with the customer:anduril label.
# Requires: gh (GitHub CLI), jq

PROJECT_ID="PVT_kwDOAziYVs4ALJ_4"
TMPFILE=$(mktemp)
AFTER=""
HAS_NEXT_PAGE=true

echo "[" >"$TMPFILE"
FIRST=1

while $HAS_NEXT_PAGE; do
  if [ -z "$AFTER" ]; then
    QUERY='
      query {
        node(id: "'"$PROJECT_ID"'") {
          ... on ProjectV2 {
            items(first: 100) {
              pageInfo { hasNextPage endCursor }
              nodes {
                content {
                  __typename
                  ... on Issue {
                    title
                    number
                    labels(first: 20) { nodes { name } }
                  }
                  ... on PullRequest {
                    title
                    number
                    labels(first: 20) { nodes { name } }
                  }
                }
                fieldValues(first: 40) {
                  nodes {
                    __typename
                    ... on ProjectV2ItemFieldSingleSelectValue {
                      name
                      field { ... on ProjectV2FieldCommon { name } }
                    }
                    ... on ProjectV2ItemFieldTextValue {
                      text
                      field { ... on ProjectV2FieldCommon { name } }
                    }
                  }
                }
              }
            }
          }
        }
      }
    '
    RESULT=$(gh api graphql -f query="$QUERY")
  else
    QUERY='
      query ($after: String!) {
        node(id: "'"$PROJECT_ID"'") {
          ... on ProjectV2 {
            items(first: 100, after: $after) {
              pageInfo { hasNextPage endCursor }
              nodes {
                content {
                  __typename
                  ... on Issue {
                    title
                    number
                    labels(first: 20) { nodes { name } }
                  }
                  ... on PullRequest {
                    title
                    number
                    labels(first: 20) { nodes { name } }
                  }
                }
                fieldValues(first: 40) {
                  nodes {
                    __typename
                    ... on ProjectV2ItemFieldSingleSelectValue {
                      name
                      field { ... on ProjectV2FieldCommon { name } }
                    }
                    ... on ProjectV2ItemFieldTextValue {
                      text
                      field { ... on ProjectV2FieldCommon { name } }
                    }
                  }
                }
              }
            }
          }
        }
      }
    '
    RESULT=$(gh api graphql -f query="$QUERY" -F after="$AFTER")
  fi

  NODES=$(echo "$RESULT" | jq '.data.node.items.nodes')
  COUNT=$(echo "$NODES" | jq 'length')
  if [ "$COUNT" -gt 0 ]; then
    if [ $FIRST -eq 0 ]; then
      echo "," >>"$TMPFILE"
    fi
    echo "$NODES" | jq -c '.[]' | paste -sd, - >>"$TMPFILE"
    FIRST=0
  fi

  HAS_NEXT_PAGE=$(echo "$RESULT" | jq -r '.data.node.items.pageInfo.hasNextPage')
  if [ "$HAS_NEXT_PAGE" = "true" ]; then
    AFTER=$(echo "$RESULT" | jq -r '.data.node.items.pageInfo.endCursor')
  else
    break
  fi
done

echo "]" >>"$TMPFILE"

jq '
  .[] |
  if (.content != null and (.content.title // null) != null) or (.fieldValues.nodes // [] | map(select(.field.name == "Title")) | length > 0) then
    if .content == null then
      {
        item_type: "DraftNote",
        custom_type: (.fieldValues.nodes // [] | map(select(.field.name == "Type") | .name // .text) | .[0] // null),
        title: (.fieldValues.nodes // [] | map(select(.field.name == "Title") | .text) | .[0] // ""),
        id: null,
        labels: [],
        status: (.fieldValues.nodes // [] | map(select(.field.name == "Status") | .name // .text) | .[0] // ""),
        anduril_priority: (.fieldValues.nodes // [] | map(select(.field.name == "Anduril Priority") | .name // .text) | .[0] // ""),
        on_roadmap: (.fieldValues.nodes // [] | map(select(.field.name == "On Roadmap Board") | .name // .text) | .[0] // "")
      }
    else
      {
        item_type: (.content.__typename // "Unknown"),
        custom_type: (.fieldValues.nodes // [] | map(select(.field.name == "Type") | .name // .text) | .[0] // null),
        title: (.content.title // ""),
        id: (.content.number // null),
        labels: (.content.labels.nodes // [] | map(.name)),
        status: (.fieldValues.nodes // [] | map(select(.field.name == "Status") | .name // .text) | .[0] // ""),
        anduril_priority: (.fieldValues.nodes // [] | map(select(.field.name == "Anduril Priority") | .name // .text) | .[0] // ""),
        on_roadmap: (.fieldValues.nodes // [] | map(select(.field.name == "On Roadmap Board") | .name // .text) | .[0] // "")
      }
    end
  else
    empty
  end
' "$TMPFILE" |
# Filter to only those with customer:anduril in the labels list
jq 'select(.labels | index("customer:anduril"))'

rm "$TMPFILE"
