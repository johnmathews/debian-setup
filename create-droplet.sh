#!/bin/bash

CONFIG_FILE="droplet-config.yaml"

# Parsing YAML
NAME=$(yq e '.name' "$CONFIG_FILE")
SIZE=$(yq e '.size' "$CONFIG_FILE")
IMAGE=$(yq e '.image' "$CONFIG_FILE")
REGION=$(yq e '.region' "$CONFIG_FILE")
MONITORING=$(yq e '.enable_monitoring' "$CONFIG_FILE")
TAGS=$(yq e '.tags[]' "$CONFIG_FILE" | tr '\n' ',' | sed 's/,$//')

# Constructing command
CMD="doctl compute droplet create $NAME --size $SIZE --image $IMAGE --region $REGION"

# Conditional flags
if [ "$MONITORING" = "true" ]; then
	CMD+=" --enable-monitoring"
fi

if [ "$TAGS" != "" ]; then
	CMD+=" --tag-names=$TAGS"
fi

CMD+=" --user-data-file=./setup-droplet.sh"

echo "command: $CMD"
echo ""
eval "$CMD"
