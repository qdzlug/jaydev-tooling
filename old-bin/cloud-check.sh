#!/usr/bin/env bash
#
# Hacky shell script to get current cloud spend...
#
MONTH_YEAR=$(date +'%m %Y' | awk '!$1{$1=12;$2--}1')
M="${MONTH_YEAR% *}"
Y="${MONTH_YEAR##* }"
D="$(cal $M $Y | paste -s - | awk '{print $NF}')"
START_DATE=$(printf '%s-%02s-01' $Y $M)
END_DATE=$(printf '%s-%02s-%s' $Y $M $D)

figlet "Cloud Spend"
echo 
echo Approximate month to date as of "$(date)"
echo "Start: " "${START_DATE}"
echo "End  : " "${END_DATE}"
echo 



# AWS
export AWS_PROFILE=f5
ACOST=$(aws ce get-cost-and-usage --time-period Start="${START_DATE}",End="${END_DATE}" --granularity MONTHLY --metrics "BlendedCost" | jq '.ResultsByTime | .[].Total.BlendedCost.Amount | tonumber' | awk '{printf("%6.2f\n",$1)}')
echo "AWS BizDev     :" "${ACOST}"

export AWS_PROFILE=community
ACOST=$(aws ce get-cost-and-usage --time-period Start="${START_DATE}",End="${END_DATE}" --granularity MONTHLY --metrics "BlendedCost" | jq '.ResultsByTime | .[].Total.BlendedCost.Amount | tonumber' | awk '{printf("%6.2f\n",$1)}')
echo "AWS Community  :" "${ACOST}"

# Azure
SUBSCRIPTIONS="7a0bb4ab-c5a7-46b3-b4ad-c10376166020 9bf57fa0-f5be-4dab-8f4b-364e77f7930e"

get_costs () {

    # the sed piece converts scientific notation to a format that can be processed by `bc`
    # see https://stackoverflow.com/a/12882612/231644
    TMP_FILE="$(mktemp)"
    az consumption usage list --start-date "${START_DATE}" --end-date "${END_DATE}" 2>/dev/null | jq -r '.[] | .pretaxCost' \
    | sed -E 's/([+-]?[0-9.]+)[eE]\+?(-?)([0-9]+)/(\1*10^\2\3)/g' >> "${TMP_FILE}"
    COST=$(paste -sd+ "${TMP_FILE}" | bc | head -1 | sed 's/\\$//')
    rm -f "${TMP_FILE}"

    printf "%.2f\n" "${COST}"
}


for SUB in ${SUBSCRIPTIONS} ; do
  az account set --subscription "${SUB}"
  COST=$(get_costs)
  if [[ $SUB == 7a0bb4ab-c5a7-46b3-b4ad-c10376166020 ]] ; then
      echo "Azure BizDev   :" "${COST}"
  elif [[ "${SUB}" == 9bf57fa0-f5be-4dab-8f4b-364e77f7930e ]] ; then
      echo "Azure Community:" "${COST}"
  else
      echo "${SUB}": "${COST}"
  fi 
done

# Digital Ocean
DCOST=$(doctl balance get -o json | jq '(.month_to_date_usage | tonumber)+(.account_balance | tonumber)')
echo "Digital Ocean  :" "${DCOST}"

# Linode
LCOST=$(linode-cli account view --json 2>/dev/null | jq '.[].balance'+'.[].balance_uninvoiced')
echo "Linode         :" "${LCOST}"
